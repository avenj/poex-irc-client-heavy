package POEx::IRC::Client::Heavy::State::PresentUser;

use Defaults::Modern;


use Moo; use MooX::late;

has prefixes => (
  lazy      => 1,
  is        => 'ro',
  isa       => ArrayObj,
  coerce    => 1,
  builder   => sub { [] },
);


1;

=pod

=head1 NAME

POEx::IRC::Client::Heavy::State::PresentUser

=head1 SYNOPSIS

Used internally by L<POEx::IRC::Client::Heavy::State>

=head1 DESCRIPTION

This class defines struct-like objects representing the state of a user
present on a L<POEx::IRC::Client::Heavy::State::Channel>.

See L<POEx::IRC:Client::Heavy::State>.

=head2 prefixes

A L<List::Objects::WithUtils::Array> containing currently-visible status
prefixes for the present user.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=begin Pod::Coverage

new

=end Pod::Coverage

=cut
