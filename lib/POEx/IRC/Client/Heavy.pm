package POEx::IRC::Client::Heavy;

use 5.10.1;
use Moo;
use POE;
use Carp 'confess';

extends 'POEx::IRC::Client::Lite';

#### TODO
## CAP negotiation.
##   We have multi-prefix support in our WHO parser.
##   Filter supports tags; we can support intents and receive server-time
##   Need sasl, extended-join/-notify, tls
## ISON  ?
## NAMES
## timers to issue WHO periodically for seen operators
## methods to check for shared channels
##  hooks in quit/part/disconnect to clear no-longer-seen users/channels

use POEx::IRC::Client::Heavy::State;

use IRC::Message::Object 'ircmsg';
use IRC::Toolkit;

use List::Objects::WithUtils;

use MooX::Role::Pluggable::Constants;

has state => (
  lazy    => 1,
  is      => 'ro',
  writer  => '_set_state',
  default => sub {
    POEx::IRC::Client::Heavy::State->new
  },
);

sub casemap { $_[0]->state->casemap }
with 'IRC::Toolkit::Role::CaseMap';

has _isupport_lines => (
  lazy    => 1,
  is      => 'ro',
  writer  => '_set_isupport_lines',
  default => sub { array },
);


### Overrides.

## FIXME override _send to do flood prot ?
##  actually, see POEx::IRC::Backend TODO

around ircsock_disconnect => sub {
  my $orig = shift;
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  my ($conn, $str) = @_[ARG0, ARG1];
  
  $self->_clear_conn if $self->_has_conn;
  
  my $connected_to = $self->state->server_name;
  $self->_set_state( $self->_build_state );
  
  $self->emit( 'irc_disconnected', $str, $connected_to );
};

around _ctcp => sub {
  my $orig = shift;
  my ($kernel, $self)        = @_[KERNEL, OBJECT];
  my ($type, $target, @data) = @_[ARG0 .. $#_];

  $type = uc $type;

  if ($type eq 'ACTION' && $self->state->has_capabs('intents')) {
    $self->send(
      ev(
        command => 'privmsg',
        params  => [ $target, join(' ', @data) ],
        tags    => { intent => 'ACTION' },
      )
    )
  } else {
    my $quoted = ctcp_quote( join(' ', $type, @data) );
    $self->send(
      ev(
        command => 'privmsg',
        params  => [ $target, $quoted ],
      )
    )
  }
};


### Public.
## FIXME these should maybe have POE counterparts
sub monitor {
  ## FIXME transparently use NOTIFY if no MONITOR support?
}

sub unmonitor {
  ## FIXME
}

sub who {
  my ($self, $target, $whox) = @_;

  if ($whox || $self->state->isupport->whox) {
    ## Send WHOX, hope for a compliant implementation.
    $self->send( 
      ev( 
        command => 'who', params => [ $orig, '%tcnuhafr,912' ] 
      ) 
    );
  } else {
    ## No WHOX, send WHO.
    $self->send(
      ev( 
        command => 'who', params => [ $orig ] 
      )
    );
  }

  $self
}

### Our handlers.

sub P_preregister {
  my (undef, $self) = splice @_, 0, 2;

  ## Negotiate CAPAB
  my @enabled_caps = qw/
    away-notify
    account-notify
    extended-join
    intents
    multi-prefix
    server-time
  /;

  for my $cap (@enabled_caps) {
    ## Spec says the server should ACK or NAK the whole set.
    ## ... not sure if sending one at a time is the right thing to do
    ## ... for now, we're doing it
    $self->send( 
      ev( command => 'cap', params => [ 'req', $cap ] ),
      ev( command => 'cap', params => [ 'end' ] )
    )
  }

  EAT_NONE
}

sub N_irc_cap {
  my (undef, $self) = splice @_, 0, 2;
  my $ircev = ${ $_[0] };

  my (undef, $cmd, $capstr) = @{ $ircev->params };
  my @caps = split ' ', $capstr;

  if ($cmd eq 'ack') {
    for my $thiscap (@caps) {
      my $maybe_prefix = substr $thiscap, 0, 1;
      if (grep {; $_ eq $maybe_prefix } ('-', '=', '~')) {
        my $actual = $thiscap;
        substr $actual, 0, 1, '';
        
        for ($maybe_prefix) {
          when ('-') {
            ## Negated.
            $self->state->clear_capabs($actual);
            $self->emit( 'cap_cleared', $actual );
          }
          when ('=') {
            ## Sticky.
            ## We don't track these, at the moment.
            $self->state->add_capabs($actual);
            $self->emit( 'cap_added', $actual );
          }
          when ('~') {
            ## Requires an ACK
            $self->state->add_capabs($actual);
            $self->emit( 'cap_added', $actual );
            $self->send(
              ev( command => 'cap', params  => [ 'ack', $actual ] )
            )
          }
          
        }

      } else {
        ## Not prefixed.
        $self->state->add_capabs($thiscap);
        $self->emit( 'cap_added', $thiscap );
      }

    }
  }

  EAT_NONE
}

sub N_irc_001 {
  my (undef, $self) = splice @_, 0, 2;
  my $ircev = ${ $_[0] };

  $self->state->_set_server_name( $ircev->prefix );

  $self->state->_set_nick_name(
    (split ' ', $ircev->raw_line)[2]
  );

  $self->_set_isupport_lines( array );

  EAT_NONE
}

sub N_irc_005 {
  my (undef, $self) = splice @_, 0, 2;
  my $ircev = ${ $_[0] };

  ##  Accumulate and preserve isupport lines
  ##  Feed the whole set to parse_isupport as we get 005s
  $self->_isupport_lines->push( $ircev->raw_line );
  $self->state->create_isupport( $self->_isupport_lines->all );

  EAT_NONE
}

sub N_irc_332 {
  ## Topic
  my (undef, $self) = splice @_, 0, 2;
  my $ircev = ${ $_[0] };

  my (undef, $target, $topic) = @{ $ircev->params };

  $self->state->update_channel( $target =>
    topic => $self->state->create_struct( Topic =>
      topic => $topic
    ),
  );

  EAT_NONE
}

sub N_irc_333 {
  ## Topic setter & TS
  my (undef, $self) = splice @_, 0, 2;
  my $ircev = ${ $_[0] };

  my (undef, $target, $setter, $ts) = @{ $ircev->params };
 
  $self->state->update_channel( $target =>
    topic => $self->state->create_struct( Topic =>
      set_at => $ts,
      set_by => $setter,
    ),
  );

  EAT_NONE
}

sub N_irc_352 {
  ## WHO reply
  my (undef, $self) = splice @_, 0, 2;
  my $ircev = ${ $_[0] };

  ## FIXME get / update other vars:
  my (
    undef,      ## Target (us)
    $target,    ## Channel
    undef,      ## Username
    undef,      ## Hostname
    undef,      ## Servername
    $nick,      ## Nickname
    $status,    ## H*@ f.ex
    undef       ## Hops + Realname
  ) = @{ $ircev->params };
  
  ## FIXME kill this
  ## FIXME accumulate params and use update_channel / update_user interfaces
  ##  should open the door to using immutable objs
  my $chan_obj = $self->state->get_channel($target);
  my $user_obj = $self->state->get_user($nick);
  return EAT_NONE unless defined $chan_obj and defined $user_obj;
  
  my @status_bits = split '', $status;
  my $here_or_not = shift @status_bits;
  $here_or_not eq 'G' ? $user_obj->is_away(1) : $user_obj->is_away(0) ;
  ## FIXME track these via WHO on a timer if we don't have away-notify?

  if (grep {; $_ eq '*' } @status_bits) {
    $user_obj->is_oper(1);
    ## FIXME track these (timer?)
  }

  ## FIXME state method for this?
  my %pfx_chars   = map {; $_ => 1 } values %{
    $self->state->isupport->prefix 
      || +{ o => '@', v => '+' } 
  };

  ## FIXME new state methods:
  my $current_ref = $chan_obj->present->{ $self->upper($nick) };
  my %current     = map {; $_ => 1 } @$current_ref;

  ## This supports IRCv3.1 multi-prefix extensions:
  for my $bit (@status_bits) {
    push @$current_ref, $bit
      if exists $pfx_chars{$bit}
      and not $current{$bit};
  }

  EAT_NONE
}

sub N_irc_354 {
  ## WHOX reply
  my (undef, $self) = splice @_, 0, 2;
  my $ircev = ${ $_[0] };
  ## FIXME check for correctness
  ## Seems these may vary, esp. with (old?) ircu
  ## Cannot seem to find very many people with useful information on the
  ## topic, not sure I can be arsed to dig deep on it myself . . .
  my (
    $tag,       ## Numeric tag
    $channel,   ## Channel
    $user,      ## Username
    $host,      ## Hostname
    $nick,      ## Nickname
    $status,    ## H*@ etc
    $account,   ## Account or '0'
    $realname   ## Realname (no hops)
  ) = @{ $ircev->params };

  $account = undef if $account eq '0';

  my @status_bits = split '', $status;
  my $here_or_not = shift @status_bits;
  $here_or_not eq 'G' ? $user_obj->is_away(1) : $user_obj->is_away(0) ;
  ## FIXME rest of status parser
  ## FIXME update Structs appropriately


  ## FIXME hum. may reach end-of-who before we have all replies,
  ##  according to ircu behavior?
  ##  Use NAMES to build full list and reissue WHO for incomplete
  ##  User structs...?

  EAT_NONE
}


sub N_irc_730 {
  ## MONONLINE
  my (undef, $self) = splice @_, 0, 2;
  return unless $self->state->isupport->monitor;

  my $ircev = ${ $_[0] };
  my @targets = split /,/, $ircev->params->[1];
  $self->emit( 'monitor_online', @targets );

  EAT_NONE
}

sub N_irc_731 {
  ## MONOFFLINE
  my (undef, $self) = splice @_, 0, 2;
  return unless $self->state->isupport->monitor;

  my $ircev = ${ $_[0] };
  my @targets = split /,/, $ircev->params->[1];
  $self->emit( 'monitor_offline', @targets );

  EAT_NONE
}

sub N_irc_734 {
  ## MONLISTFULL
  my (undef, $self) = splice @_, 0, 2;
  return unless $self->state->isupport->monitor;

  my $ircev = ${ $_[0] };
  my (undef, $limit, $targets) = @{ $ircev->params };
  $self->emit( 'monitor_list_full', $limit, split(/,/, $targets) );

  EAT_NONE
}

## FIXME get NAMES reply

sub N_irc_account {
  ## account-notify
  my (undef, $self) = splice @_, 0, 2;
  my $ircev = ${ $_[0] };
  
  my ($nick, $user, $host) = parse_user( $ircev->prefix );
  
  my $user_obj = $self->state->get_user($nick);
  unless ($user_obj) {
    warn "Received ACCOUNT from server for unknown user $nick";
    return EAT_NONE
  }
  
  my $acct = $ircev->params->[0];
  if ($acct eq '*') {
    $user_obj->account('');
    $self->emit( 'account_notify_cleared', $nick );
  } else {
    $user_obj->account($acct);
    $self->emit( 'account_notify_set', $nick, $acct );
  }

  EAT_NONE
}

sub N_irc_away {
  ## away-notify
  my (undef, $self) = splice @_, 0, 2;
  my $ircev = ${ $_[0] };

  my ($nick, $user, $host) = parse_user( $ircev->prefix );

  my $user_obj = $self->state->get_user($nick);
  unless ($user_obj) {
    warn "Received AWAY from server for unknown user $nick";
    return EAT_NONE
  }

  if (@{ $ircev->params }) {
    $user_obj->is_away(1);
  } else {
    $user_obj->is_away(0);
  }

  EAT_NONE
}

sub N_irc_nick {
  my (undef, $self) = splice @_, 0, 2;
  my $ircev = ${ $_[0] };
  ## FIXME update our nick as-needed
  ##  Update our channels as-needed
  EAT_NONE
}

sub N_irc_mode {
  my (undef, $self) = splice @_, 0, 2;
  my $ircev = ${ $_[0] };
  my ($target, $modestr, @params) = @{ $ircev->params };

  my $chan_obj = $self->state->get_channel($target);

  my (@always, @whenset);
  if (my $cmodes = $self->state->isupport->chanmodes) {
    @always  = @{ $cmodes->always };
    @whenset = @{ $cmodes->whenset };
  }

  ## FIXME
  ##  Needs to use mode_to_array
  ##  Needs to be able to cancel earlier changes e.g. -o+o-o+o X X X X
  my $mode_hash = mode_to_hash( $modestr,
    params  => [ @params ],
    ( @always  ?  (param_always => \@always)  : () ),
    ( @whenset ?  (param_set    => \@whenset) : () ),
  );

  my %prefixes = %{ 
    $self->state->isupport->prefix || +{ 'o' => '@', 'v' => '+' }
  };

  MODE_ADD: for my $char (keys %{ $mode_hash->{add} }) {
    next MODE_ADD unless exists $prefixes{$char}
      and ref $mode_hash->{add}->{$char} eq 'ARRAY';
    my $param = $mode_hash->{add}->{$char}->[0];
    my $this_user;
    unless ($this_user = $chan_obj->present->{ $self->upper($param) }) {
      warn "Mode change for nonexistant user $param";
      next MODE_ADD
    }
    push @$this_user, $prefixes{$char}
  }

  MODE_DEL: for my $char (keys %{ $mode_hash->{del} }) {
    next MODE_DEL unless exists $prefixes{$char}
      and ref $mode_hash->{del}->{$char} eq 'ARRAY';
    my $param = $mode_hash->{del}->{$char}->[0];
    my $this_user;
    unless ($this_user = $chan_obj->present->{ $self->upper($param) }) {
      warn "Mode change for nonexistant user $param";
      next MODE_DEL
    }
    @$this_user = grep {; $_ ne $prefixes{$char} } @$this_user
  }

  EAT_NONE
}

sub N_irc_join {
  my (undef, $self) = splice @_, 0, 2;
  my $ircev = ${ $_[0] };

  my ($nick, $user, $host) = parse_user( $ircev->prefix );

  ## FIXME does our own JOIN include account in extended-join ?
  my ($account, $orig);
  if ($self->state->has_capabs('extended-join')) {
    ($account, $orig) = @{ $ircev->params };
    $account = undef if $account eq '*';
  } else {
    $orig = $ircev->params->[0];
  }

  my $target = $self->upper($orig);
  $nick      = $self->upper($nick);

  if ( $self->equal($nick, $self->state->nick_name) ) {
    ## Us. Add new Channel struct.
    ## FIXME new state syntax. can create an initial Topic obj here
    $self->state->update = Channel->new(
      name      => $orig,
      nicknames => {},
      topic     => Topic->new(
        set_by => '',
        set_at => 0,
        topic  => '',
      ),
    );
    ## ... and request a WHO(X):
    $self->who( $orig );
 } else {
    ##  Not us. Add or update User struct.
    $self->state->update_user( $nick,
      user => $user,
      host => $host,
      ( defined $account ? (account => $account) : () ),
    );
    $self->who( $nick );
  }

  my $chan_obj = $self->state->get_channel($target);
  $self->state->get_channel($target)->present->set( $nick => array );

  EAT_NONE
}

sub N_irc_part {
  my (undef, $self) = splice @_, 0, 2;
  my $ircev = ${ $_[0] };

  my ($nick)  = parse_user( $ircev->prefix );

  my $target = $self->upper( $ircev->params->[0] );
  $nick      = $self->upper( $nick );
  
  delete $self->state->channels->{$target};

  my $seen;
  while (my ($channel, $chan_obj) = each %{ $self->state->channels }) {
    $seen++ if exists $chan_obj->present->{$nick};
  }
  $self->state->del_user($nick) unless $seen;
  
  EAT_NONE
}

sub N_irc_quit {
  my (undef, $self) = splice @_, 0, 2;
  my $ircev = ${ $_[0] };

  my ($nick) = parse_user( $ircev->prefix );
  $nick      = $self->upper($nick);

  while (my ($channel, $chan_obj) = each %{ $self->state->channels }) {
    delete $chan_obj->present->{$nick}
  }

  $self->state->del_user($nick);

  EAT_NONE
}

sub N_irc_topic {
  my (undef, $self) = splice @_, 0, 2;
  my $ircev = ${ $_[0] };
  
  my ($nick, $user, $host) = parse_user( $ircev->prefix );
  my ($target, $str) = @{ $ircev->params };
  $target = $self->upper($target);

  ## FIXME object api for new State
 
  my $chan_obj = $self->state->channels->{$target};
  $chan_obj->topic( Topic->new(
      set_at => time(),
      set_by => $ircev->prefix,
      topic  => $str,
    )
  );

  EAT_NONE
}



1;


__END__

=pod

=head1 NAME

POEx::IRC::Client::Heavy - Stateful IRCv3 client

=head1 SYNOPSIS

FIXME

=head1 DESCRIPTION

This is a mostly-IRCv3-compatible state-tracking subclass of 
L<POEx::IRC::Client::Lite>.

=head2 IRCv3 compatibility

Supported:

B<away-notify>

B<account-notify>

B<extended-join>

B<intents>

B<multi-prefix>

B<server-time>

B<MONITOR>


B<sasl> and B<tls> are currently missing. TLS may be a challenge due to a lack of
STARTTLS-compatible POE Filters/Components; input/patches welcome, of course.


FIXME

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut

