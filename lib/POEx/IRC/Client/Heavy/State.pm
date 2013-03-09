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
  predicate => '_has_isupport',
);

sub create_isupport {
  my ($self, @items) = @_;
  $self->_set_isupport(
    $self->create_struct( ISupport => @items )
  )
}

sub casemap {
  my ($self) = @_;
  return 'rfc1459' unless $self->_has_isupport;
  $self->isupport->casemap || 'rfc1459'
}

with 'IRC::Toolkit::Role::CaseMap';

## Channels
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

sub update_topic {
  my ($self, $channel, %params) = @_;
  
  if (my $struct = $self->get_channel($channel)) {
    my $topic;

    if ($topic = $struct->topic) {
      $topic = $topic->new_with_params(%params)
    } else {
      $topic = Topic->new(%params)
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

sub get_status_prefix {
  my ($self, $channel, $nick, $prefix) = @_;
  confess "Expected a channel and nickname"
    unless defined $channel and defined $nick;

  my $chan_obj = $self->_chans->{ $self->upper($channel) };
  unless (defined $chan_obj) {
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
  delete $self->_users->{ $self->upper($nick) }
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

FIXME this is the POD as extracted from Lite


=head2 State

The State struct provides some very basic state information that can be
queried via accessor methods:

=head3 nick_name

  my $current_nick = $irc->state->nick_name;

Returns the client's current nickname.

=head3 server_name

  my $current_serv = $irc->state->server_name;

Returns the server's announced name.

=head3 get_isupport

  my $casemap = $irc->state->get_isupport('casemap');

Returns ISUPPORT values, if they are available.

If the value is a KEY=VALUE pair (e.g. 'MAXMODES=4'), the VALUE portion is
returned.

A value that is a simple boolean (e.g. 'CALLERID') will return '-1'.

=head3 get_channel

  my $chan_st = $irc->state->get_channel($channame);

If the channel is found, returns a Channel struct with the following accessor
methods:

=head4 nicknames

  my @users = keys %{ $chan_st->nicknames };

A HASH whose keys are the users present on the channel.

If a user has status modes, the values are an ARRAY of status prefixes (f.ex,
o => '@', v => '+', ...)

=head4 status_prefix_for


=head4 topic

  my $topic_st = $chan_st->topic;
  my $topic_as_string = $topic_st->topic();

The Topic struct provides information about the current channel topic via
accessors:

=over

=item *

B<topic> is the actual topic string

=item *

B<set_at> is the timestamp of the topic change

=item *

B<set_by> is the topic's setter

=back

=cut
