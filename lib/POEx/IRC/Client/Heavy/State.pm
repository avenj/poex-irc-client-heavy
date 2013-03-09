package POEx::IRC::Client::Heavy::State;

use 5.10.1;
use Moo;
use MooX::Types::MooseLike::Base ':all';

use Carp;
use Scalar::Util 'weaken';

use IRC::Toolkit;

use POEx::IRC::Client::Heavy::State::Channel;
use POEx::IRC::Client::Heavy::State::Topic;
use POEx::IRC::Client::Heavy::State::User;
sub Channel () { 'POEx::IRC::Client::Heavy::State::Channel' }
sub Topic   () { 'POEx::IRC::Client::Heavy::State::Topic'   }
sub User    () { 'POEx::IRC::Client::Heavy::State::User'    }

use namespace::clean;

sub create_struct {
  ## Factory method to make it easier for subclasses to build ::Structs
  my ($self, $type) = splice @_, 0, 2;
  my $obj;
  for (lc $type) {
    $obj = Channel->new(@_)   when 'channel';
    $obj = Topic->new(@_)     when 'topic';
    $obj = User->new(@_)      when 'user';
    $obj = parse_isupport(@_) when 'isupport';
    confess "cannot create struct - unknown type $type"
  }
  $obj
}

##    nick_name
##    server_name
has $_ => (
  lazy    => 1,
  is      => 'ro',
  isa     => Str,
  writer  => '_set_'.$_,
  default => sub { '' },
) for qw/ 
  nick_name 
  server_name 
/;

##    _users
##    _chans
##    _capabs
has $_ => (
  lazy    => 1,
  is      => 'ro',
  isa     => HashRef,
  default => sub { {} },
) for qw/ 
  _users 
  _chans
  _capabs
/;

has isupport => (
  ## Should be created via create_isupport
  ##  (after accumulating 005s)
  is        => 'ro',
  isa       => Object,
  writer    => '_set_isupport',
  predicate => 'has_isupport',
);

sub create_isupport {
  my ($self, @items) = @_;
  $self->_set_isupport(
    $self->create_struct( ISupport => @items )
  )
}

sub casemap {
  my ($self) = @_;
  return 'rfc1459' unless $self->has_isupport;
  $self->isupport->casemap || 'rfc1459'
}

with 'IRC::Toolkit::Role::CaseMap';

## Channels
sub list_channels {
  map {; $_->name } values %{ $_[0]->_chans }
}

sub update_channel {
  my ($self, $channel, %params) = @_;
  my $upper = $self->upper($channel);

  if (my $struct = $self->get_channel($channel)) {
    $self->_chans->{$upper} = $struct->new_with_params(
      %params
    )
  } else {
    $self->_chans->{$upper} = $self->create_struct( Channel =>
      name => $channel,
      %params
    );
  }

  $self->_chans->{$upper}
}

sub update_channel_topic {
  my ($self, $channel, %params) = @_;
  
  if (my $struct = $self->get_channel($channel)) {
    my $topic;

    if ($topic = $struct->topic) {
      $topic = $topic->new_with_params(%params)
    } else {
      $topic = $self->create_struct( Topic => %params );
    }

    return $self->update_channel( $channel =>
      topic => $topic,
    )
  }

  confess "Cannot update_topic for unknown channel $channel"
}

sub del_channel {
  my ($self, $channel) = @_;
  ## confess() if we don't know this channel:
  $self->get_channel($channel);
  delete $self->_chans->{ $self->upper($channel) }
}

sub get_channel {
  my ($self, $channel) = @_;
  confess "Expected a channel name" unless defined $channel;
  $self->_chans->{ $self->upper($channel) }
}

sub has_channel {
  ## Same as get_channel, but a bit more natural to use.
  my ($self, $channel) = @_;
  $self->get_channel($channel)
}

sub channel_has_user {
  my ($self, $channel, $nick) = @_;
  confess "Expected a channel and nickname"
    unless defined $nick;

  if (my $chan_obj = $self->get_channel($channel)) {
    return $chan_obj->present->{ $self->upper($nick) }
  }

  confess "Not present on channel $channel"
}

sub add_to_channel {
  my ($self, $channel, $nick) = @_;
  confess "Expected a channel and nickname"
    unless defined $nick;

  my $chan_obj;
  unless ($chan_obj = $self->get_channel($channel)) {
    carp "Not present on channel $channel";
    return
  }

  if ($self->channel_has_user($channel, $nick)) {
    carp "Channel $channel already has user $nick";
    return
  }

  $chan_obj->present->{ $self->upper($nick) } = []
}

sub channel_user_list {
  my ($self, $channel) = @_;

  my $chan_obj;
  unless ($chan_obj = $self->get_channel($channel)) {
    carp "Not present on channel $channel";
    return
  }

  my @list;
  for my $nick (keys %{ $chan_obj->present }) {
    my $user_obj = $self->get_user($nick);
    push @list, $user_obj->nick
  }

  @list
}

sub del_from_channel {
  my ($self, $channel, $nick) = @_;
  confess "Expected a channel and nickname"
    unless defined $nick;

  my $chan_obj;
  unless ($chan_obj = $self->get_channel($channel)) {
    carp "Not present on channel $channel";
    return
  }

  return unless $self->channel_has_user($channel, $nick);

  delete $chan_obj->present->{ $self->upper($nick) }
}

sub add_status_prefix {
  my ($self, $channel, $nick, $prefix) = @_;
  confess "Expected a channel, nickname, and prefix"
    unless defined $prefix;

  my $chan_obj;
  unless ($chan_obj = $self->get_channel($channel)) {
    carp "Not present on channel $channel";
    return
  }

  unless ($self->channel_has_user($channel, $nick)) {
    carp "User $nick not present on channel $channel";
    return
  }

  my $pfxarr = $chan_obj->present->{ $self->upper($nick) };
  push @$pfxarr, $prefix unless grep {; $_ eq $prefix } @$pfxarr;

  $pfxarr
}

sub del_status_prefix {
  my ($self, $channel, $nick, $prefix) = @_;
  confess "Expected a channel, nickname, and prefix"
    unless defined $prefix;

  my $chan_obj;
  unless ($chan_obj = $self->get_channel($channel)) {
    carp "Not currently on $channel - cannot del prefix";
    return
  }

  unless ($self->channel_has_user($channel, $nick)) {
    carp "User $nick not present on channel $channel";
    return
  }

  my $pfxarr = $chan_obj->present->{ $self->upper($nick) };
  $chan_obj->present->{ $self->upper($nick) } = 
    [ grep {; $_ ne $prefix } @$pfxarr ];
}

sub get_status_prefix {
  my ($self, $channel, $nick, $prefix) = @_;
  confess "Expected a channel and nickname"
    unless defined $nick;

  my $chan_obj;
  unless ($chan_obj = $self->get_channel($channel)) {
    carp "Not currently on $channel - cannot retrieve prefix";
    return ''
  }

  my $pfx_arr = $chan_obj->present->{$nick};
  unless (defined $pfx_arr) {
    carp "User not present on $channel - $nick";
    return ''
  }

  if ($prefix) {
    ## ->get_status_prefix($chan, $nick, '@%')
    ## Returns first found (aka boolean true if found)
    for my $lookup (split '', $prefix) {
      return $lookup if grep {; $_ eq $lookup } @$pfx_arr;
    }
    return
  }

  join '', @$pfx_arr
}

sub get_status_mode {
  my ($self, $channel, $nick, $mode) = @_;
  ## FIXME like get_status_prefix but retrieve prefix modes from isupport
  ##  map user's prefixes to modes and grep
}

## Users
sub update_user {
  ## Add or update a User struct.
  my ($self, $nick, %params) = @_;
  my $upper = $self->upper($nick);

  if (my $struct = $self->get_user($nick)) {
    $self->_users->{$upper} = $struct->new_with_params(
      %params
    );
  } else {
    $self->_users->{$upper} = $self->create_struct( User =>
      nick => $nick,
      %params
    );
  }

  $self->_users->{$upper}
}

sub del_user {
  my ($self, $nick) = @_;
  $self->get_user($nick);
  my $upper = $self->upper($nick);
  for my $chan ($self->list_channels) {
    $self->del_from_channel($chan, $nick)
      if $self->channel_has_user($chan, $nick);
  }
  delete $self->_users->{$upper}
}

sub get_user {
  my ($self, $nick) = @_;
  confess "Expected a nickname" unless defined $nick;
  $self->_users->{ $self->upper($nick) }
}


## CAP
sub add_capabs {
  my ($self, @cap) = @_;
  @cap = map {; lc $_ } @cap;
  for my $thiscap (@cap) {
    $self->_capabs->{$thiscap} = 1
  }
  @cap
}

sub clear_capabs {
  my ($self, @cap) = @_;
  my @result;
  for my $thiscap (map {; lc $_ } @cap) {
    push @result, delete $self->_capabs->{$thiscap};
  }
  @result
}

sub has_capabs {
  my ($self, @cap) = @_;
  my @result;
  for my $thiscap (map {; lc $_ } @cap) {
    push @result, $thiscap if exists $self->_capabs->{$thiscap};
  }
  @result
}

sub capabs {
  my ($self) = @_;
  keys %{ $self->_capabs }
}

1;

=pod

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 Client state

=head3 nick_name

Returns the client's current nickname.

=head3 server_name

Returns the server's announced name.

=head3 isupport

Returns the current L<IRC::Toolkit::ISupport> object.

=head3 has_isupport

Boolean true if an L</isupport> object has been built.

=head3 casemap

Returns the IRC CASEMAPPING= value for the current server as seen by
L</isupport>, or 'rfc1459' if we haven't parsed ISUPPORT yet.

=head3 capabs

  my @caps = $state->capabs;

Returns the list of declared CAP capabilities.

=head3 add_capabs

  $state->add_capabs( @capabs );

Adds declared CAP capabilities.

=head3 clear_capabs

  $state->clear_capabs( @capabs );

Clears declared CAP capabilities.

=head3 has_capabs

  $state->has_capabs( @capabs );

Given a list of CAP capabilities, returns the list of (lowercased) CAPs that
were found in the L</capabs> list.

=head2 Channel state

=head3 list_channels

Returns the list of currently-seen channels.

=head3 update_channel

  $state->update_channel( $chan_name =>
    %params
  );

Update the L<POEx::IRC::Client::Heavy::State::Channel> struct for a named
channel.

=head3 update_channel_topic

  $state->update_channel_topic( $chan_name =>
    topic  => $string,
    set_at => $ts,
    set_by => $host,
  );

Update the L<POEx::IRC::Client::Heavy::State::Topic> struct for a named
channel.

=head3 del_channel

  $state->del_channel($chan_name);

Delete a named channel.

=head3 get_channel

  $state->get_channel($chan_name);

Retrieve a named channel's L<POEx::IRC::Client::Heavy::State::Channel> struct.

=head3 has_channel

  $state->has_channel($chan_name);

Boolean true if we are aware of this channel.

=head3 channel_has_user

  $state->channel_has_user($channel, $nick);

Boolean true if the named user is present in the named channel's state.

=head3 add_to_channel

  $state->add_to_channel($channel, $nick);

Add a given nickname to a channel's state.

=head3 channel_user_list

  $state->channel_user_list($channel);

The list of known users on a named channel.

=head3 del_from_channel

  $state->del_from_channel($channel, $nick);

Delete a named user from a channel's state.

=head2 User state

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
