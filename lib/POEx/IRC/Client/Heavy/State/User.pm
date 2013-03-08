package POEx::IRC::Client::Heavy::State::User;
use 5.10.1;
use strictures 1;
use Carp;

use Storable 'dclone';

sub new {
  my ($cls, %params) = @_;
  my $self = +{};

  my @required = qw/
    nick
    user
    host
    realname
  /;

  my @optional = qw/
    account
  /;

  my @bool = qw/
    is_away
    is_oper
  /;

  for my $opt (@required) {
    confess "Missing required param $opt"
      unless defined $params{$opt};
    $self->{$opt} = $params{$opt}
  }

  for my $opt (@optional, @bool) {
    $self->{$opt} = $params{$opt}
      if defined $params{$opt}
  }

  bless $self, $cls;
  $self
}

sub new_with_params {
  my ($self, %params) = @_;
  my %cur = %{ dclone $self };
  @cur{keys %params} = values %params;
  ref($self)->new(%cur)
}

sub account  { $_[0]->{account} }
sub nick     { $_[0]->{nick}    }
sub user     { $_[0]->{user}    }
sub host     { $_[0]->{host}    }
sub realname { $_[0]->{realname} }
sub is_away  { $_[0]->{is_away} // 0 }
sub is_oper  { $_[0]->{is_oper} // 0 }

1;
