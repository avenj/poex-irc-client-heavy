package POEx::IRC::Client::Heavy::State::User;
use 5.10.1;
use strictures 1;
use Carp;

use Role::Tiny::With;
use POEx::IRC::Client::Heavy::State::Struct;
with 'POEx::IRC::Client::Heavy::Role::Clonable';

has_ro account  => ();
has_ro nick     => ();
has_ro user     => ();
has_ro host     => ();
has_ro realname => ();
has_ro is_away  => ( default  => 0 );
has_ro is_oper  => ( default  => 0 );

sub new {
  my ($cls, %params) = @_;

  my @required = qw/
    nick
    user
    host
    realname
  /;

  for my $opt (@required) {
    confess "Missing required param $opt"
      unless defined $params{$opt};
  }

  my $self = +{%params};

  bless $self, $cls;
  $self
}

1;

=pod

=head1 NAME

POEx::IRC::Client::Heavy::State::User

=head1 SYNOPSIS

Used internally by L<POEx::IRC::Client::Heavy::State>

=head1 DESCRIPTION

This class defines struct-like objects representing the state of 
a known IRC user for L<POEx::IRC::Client::Heavy>.

These classes consume L<POEx::IRC::Client::Heavy::Role::Clonable>.

See L<POEx::IRC::Client::Heavy::State>.

=head2 nick

The user's nickname (as we saw it at construction-time).

=head2 user

The user's username ("ident").

=head2 host

The user's hostname.

=head2 realname

The user's GECOS ("real name").

=head2 account

The user's services account name, if any.

=head2 is_away

Boolean flag indicating whether the user is set AWAY.

=head2 is_oper

Boolean flag indicating whether the user is marked as an IRC operator.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
