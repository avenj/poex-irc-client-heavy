package POEx::IRC::Client::Heavy::State::User;

use Defaults::Modern;


use Moo; use MooX::late;

has account => (

);

has nick => (
  required  => 1,
  is        => 'ro',
  isa       => Str,
);

has user => (
  required  => 1,
  is        => 'ro',
  isa       => Str,
);

has host => (
  required  => 1,
  is        => 'ro',
  isa       => Str,
);

has realname => (
  lazy      => 1,
  is        => 'ro',
  isa       => Str,
  builder   => sub { '' },
);

has is_away => (
  lazy      => 1,
  is        => 'ro',
  isa       => Bool,
  builder   => sub { 0 },
);

has is_oper => (
  lazy      => 1,
  is        => 'ro',
  isa       => Bool,
  builder   => sub { 0 },
);


1;

=pod

=head1 NAME

POEx::IRC::Client::Heavy::State::User

=head1 SYNOPSIS

Used internally by L<POEx::IRC::Client::Heavy::State>

=head1 DESCRIPTION

This class defines struct-like objects representing the state of 
a known IRC user for L<POEx::IRC::Client::Heavy>.

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
