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

has_ro account  => ();
has_ro nick     => ( required => 1 );
has_ro user     => ( required => 1 );
has_ro host     => ( required => 1 );
has_ro realname => ( required => 1 );
has_ro is_away  => ( default  => 0 );
has_ro is_oper  => ( default  => 0 );

1;
