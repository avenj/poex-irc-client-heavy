package POEx::IRC::Client::Heavy::State;
use Carp;
use strictures 1;
use 5.10.1;
use Moo;
use MooX::Types::MooseLike::Base qw/
  Object
  Str
/;

use IRC::Toolkit;
use List::Objects::WithUtils;
use Module::Runtime 'use_module';

use_module($_) 
  for map {; 'POEx::IRC::Client::Heavy::State::'.$_ } qw/
    Channel
    Topic
    User
    PresentUser
/;

use namespace::clean;

=pod

=for Pod::Coverage create_struct

=cut

sub create_struct {
  ## Factory method to make it easier for subclasses to build ::Structs
  my ($self, $type) = splice @_, 0, 2;

  my ($class, $obj);
  for (lc $type) {
    $class = 'Channel'     when 'channel';
    $class = 'Topic'       when 'topic';
    $class = 'User'        when 'user';
    $class = 'PresentUser' when 'presentuser';

    $obj = parse_isupport(@_) when 'isupport';

    confess "cannot create struct - unknown type $type"
  }

  (join '::', 'POEx::IRC::Client::Heavy::State', $class)->new(@_)
}

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
  default => sub { hash },
) for qw/ 
  _users 
  _chans
  _capabs
/;

## Channels
sub channel_list {
  my ($self) = @_;
  $self->_chans->values->map(sub { $_[0]->name })
}

sub update_channel {
  my ($self, $channel, %params) = @_;
  my $upper = $self->upper($channel);

  if (my $struct = $self->get_channel($channel)) {
    $self->_chans->set( $upper => 
      $struct->new_with_params( %params )
    )
  } else {
    $self->_chans->set( $upper =>
      $self->create_struct( Channel =>
        name => $channel, %params
      )
    )
  }

  $self->_chans->get($upper)
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
  $self->_chans->delete( $self->upper($channel) )
}

sub get_channel {
  my ($self, $channel) = @_;
  confess "Expected a channel name" unless defined $channel;
  $self->_chans->get( $self->upper($channel) )
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
    return $chan_obj->present->get( $self->upper($nick) )
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

  $chan_obj->present->set( $self->upper($nick) =>
    $self->create_struct( PresentUser => () )
  );
  $chan_obj->present->get( $self->upper($nick) )
}

sub channel_user_list {
  my ($self, $channel) = @_;

  my $chan_obj;
  unless ($chan_obj = $self->get_channel($channel)) {
    carp "Not present on channel $channel";
    return
  }

  $chan_obj->present->keys->map(sub {
      $self->get_user($_[0])->nick
  })->all
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

  $chan_obj->present->delete( $self->upper($nick) )
}

sub add_status_prefix {
  my ($self, $channel, $nick, $prefix) = @_;
  confess "Expected a channel, nickname, and prefix"
    unless defined $prefix;

  my $upper   = $self->upper($nick);

  my $chan_obj;
  unless ($chan_obj = $self->get_channel($channel)) {
    carp "Not present on channel $channel";
    return
  }

  unless ($self->channel_has_user($channel, $upper)) {
    carp "User $nick not present on channel $channel";
    return
  }

  my $current = $chan_obj->present->get($upper);
  $chan_obj->present->set( $upper =>
    $current->new_with_params(
      prefixes => [ $current->prefixes->all, $prefix ],
    )
  ) unless $current->prefixes->any_items eq $prefix;

  $chan_obj->present->get($upper)->prefixes
}

sub del_status_prefix {
  my ($self, $channel, $nick, $prefix) = @_;
  confess "Expected a channel, nickname, and prefix"
    unless defined $prefix;

  my $upper   = $self->upper($nick);

  my $chan_obj;
  unless ($chan_obj = $self->get_channel($channel)) {
    carp "Not currently on $channel - cannot del prefix";
    return
  }

  unless ($self->channel_has_user($channel, $upper)) {
    carp "User $nick not present on channel $channel";
    return
  }

  my $current = $chan_obj->present->get($upper);
  $chan_obj->present->set( $upper =>
    $current->new_with_params(
      prefixes => [ $current->prefixes->grep(sub { $_[0] ne $prefix })->all ],
    )
  );

  $chan_obj->present->get($upper)->prefixes
}

sub get_status_prefix {
  my ($self, $channel, $nick, $prefix) = @_;
  confess "Expected a channel and nickname"
    unless defined $nick;

  my $chan_obj;
  unless ($chan_obj = $self->get_channel($channel)) {
    carp "Not currently on $channel - cannot retrieve prefix";
    return
  }

  my $puser = $chan_obj->present->get( $self->upper($nick) );
  unless (defined $puser) {
    carp "User not present on $channel - $nick";
    return
  }

  if ($prefix) {
    for my $lookup (split '', $prefix) {
      return $lookup if $puser->prefixes->any_items eq $lookup;
    }
    return
  }

  $puser->prefixes->join('')
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
    $self->_users->set( $upper =>
      $struct->new_with_params( %params )
    )
  } else {
    $self->_users->set( $upper =>
      $self->create_struct( User =>
        nick => $nick, %params
      )
    )
  }

  $self->_users->get($upper)
}

sub del_user {
  my ($self, $nick) = @_;
  $self->get_user($nick);
  my $upper = $self->upper($nick);

  for my $chan ($self->channel_list) {
    $self->del_from_channel($chan, $nick)
      if $self->channel_has_user($chan, $nick);
  }

  $self->_users->delete($upper)
}

sub get_user {
  my ($self, $nick) = @_;
  confess "Expected a nickname" unless defined $nick;
  $self->_users->get( $self->upper($nick) )
}


## CAP
sub add_capabs {
  my ($self, @cap) = @_;

  for my $thiscap (array(@cap)->map(sub { lc $_[0] })->all) {
    $self->_capabs->set($thiscap => 1)
  }

  $self->_capabs->keys
}

sub clear_capabs {
  my ($self, @cap) = @_;

  $self->_capabs->delete(
    array(@cap)->map(sub { lc $_[0] })->all
  )
}

sub has_capabs {
  my ($self, @cap) = @_;

  ## FIXME triggers indirect-0.29 bug? see rt83806
  use indirect;
  array(@cap)
    ->map(sub {  lc $_[0] })
    ->grep(sub { $self->_capabs->exists($_[0]) })
    ->all
}

sub capabs { $_[0]->_capabs->keys }

1;

=pod

=head1 NAME

POEx::IRC::Client::Heavy::State - Current IRC state

=head1 SYNOPSIS

Normally used via L<POEx::IRC::Client::Heavy>:

  my $state = $irc->state;
  my $nick  = $state->nick_name;

=head1 DESCRIPTION

This is the state tracker for L<POEx::IRC::Client::Heavy>, providing access to
(usually immutable) objects describing the currently-visible state.

See also:

L<POEx::IRC::Client::Heavy::State::User>

L<POEx::IRC::Client::Heavy::State::PresentUser>

L<POEx::IRC::Client::Heavy::State::Channel>

L<POEx::IRC::Client::Heavy::State::Topic>

=head2 Client state

=head3 nick_name

Returns the client's current nickname.

=head3 server_name

Returns the server's announced name.

=head3 isupport

Returns the current L<IRC::Toolkit::ISupport> object.

=head3 has_isupport

Boolean true if an L</isupport> object has been built.

=head3 create_isupport

Used internally by L<POEx::IRC::Client::Heavy> to reset the current
L</isupport> object.

Feeds parameters to L<IRC::Toolkit::ISupport> to build a new ISupport object
and replaces the current L</isupport>.

=head3 casemap

Returns the IRC CASEMAPPING= value for the current server as seen by
L</isupport>, or 'rfc1459' if we haven't parsed ISUPPORT yet.

=head3 capabs

  my @caps = $state->capabs->all;

Returns the list of declared CAP capabilities as a
L<List::Objects::WithUtils::Array>.

=head3 add_capabs

  $state->add_capabs( @capabs );

Adds declared CAP capabilities.

Used internally by L<POEx::IRC::Client::Heavy>.

=head3 clear_capabs

  $state->clear_capabs( @capabs );

Clears declared CAP capabilities.

Used internally by L<POEx::IRC::Client::Heavy>.

=head3 has_capabs

  my @capabs = $state->has_capabs(@capabs)->all;

Given a list of CAP capabilities, returns the list of (lowercased) CAPs that
were found in the L</capabs> list as a L<List::Objects::WithUtils::Array>.

=head2 Channel state

=head3 channel_list

  my @chans = $state->channel_list->all;

  my @matching = $state->channel_list->grep(
    sub { $_[0] =~ $regex }
  )->all;

Returns the list of currently-seen channels as a
L<List::Objects::WithUtils::Array>.

=head3 update_channel

  $state->update_channel( $chan_name =>
    %params
  );

Update the L<POEx::IRC::Client::Heavy::State::Channel> struct for a named
channel.

Used internally by L<POEx::IRC::Client::Heavy>.

=head3 update_channel_topic

  $state->update_channel_topic( $chan_name =>
    topic  => $string,
    set_at => $ts,
    set_by => $host,
  );

Update the L<POEx::IRC::Client::Heavy::State::Topic> struct for a named
channel.

Used internally by L<POEx::IRC::Client::Heavy>.

=head3 del_channel

  $state->del_channel($chan_name);

Delete a named channel.

Used internally by L<POEx::IRC::Client::Heavy>.

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

Used internally by L<POEx::IRC::Client::Heavy>.

=head3 channel_user_list

  $state->channel_user_list($channel);

The list of known users on a named channel.

=head3 del_from_channel

  $state->del_from_channel($channel, $nick);

Delete a named user from a channel's state.

Used internally by L<POEx::IRC::Client::Heavy>.

Returns a L<List::Objects::WithUtils::Array> containing deleted objects.

=head3 add_status_prefix

  $state->add_status_prefix( $channel =>
    $nick => '@'
  );

Add a prefix character (such as retrieved from WHO) to the 
L<POEx::IRC::Client::Heavy::State::PresentUser> struct belonging to the named
channel.

=head3 del_status_prefix

  $state->del_status_prefix( $channel =>
    $nick => '@'
  );

Delete a prefix character added via L</add_status_prefix>.

=head3 get_status_prefix

  if ( $state->get_status_prefix( $channel, $nick, '@' ) ) {
    ... 
  }

Retrieve status prefixes added via L</add_status_prefix>.

If a prefix character is specified, a boolean true value is returned if the
user has the specified prefix in state.

If no prefix is specified, the full known prefix string (e.g. '@+') is returned.

=head2 User state

=head3 update_user

  $state->update_user( $nickname =>
    %params
  );

Create or update a L<POEx::IRC::Client::Heavy::State::User> struct for a named
user.

Used internally by L<POEx::IRC::Client::Heavy>.

=head3 get_user

  $state->get_user( $nickname );

Retrieves the current L<POEx::IRC::Client::Heavy::State::User> struct for 
a named user.

=head3 del_user

  $state->del_user( $nickname );

Delete the named user from the current state.

Used internally by L<POEx::IRC::Client::Heavy>.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
