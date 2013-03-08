package POEx::IRC::Client::Heavy::State::User;
use 5.10.1;
use strictures 1;
use Carp;

use Storable 'dclone';

use POEx::IRC::Client::Heavy::State::Struct;

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

has_ro account  => ();
has_ro nick     => ();
has_ro user     => ();
has_ro host     => ();
has_ro realname => ();
has_ro is_away  => ( default  => 0 );
has_ro is_oper  => ( default  => 0 );

1;
