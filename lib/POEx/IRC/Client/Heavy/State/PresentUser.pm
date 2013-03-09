package POEx::IRC::Client::Heavy::State::PresentUser;
use strictures 1;
use Carp;
use Scalar::Util 'blessed';

use Data::Perl 'array';

use Role::Tiny::With;
use POEx::IRC::Client::Heavy::State::Struct;
with 'POEx::IRC::Client::Heavy::Role::Clonable';

use namespace::clean;

has_ro prefixes => ( default => array );

sub new {
  my ($cls, %params) = @_;
  bless +{%params}, $cls
}

1;

=pod

=head1 NAME

POEx::IRC::Client::Heavy::State::PresentUser

=head1 SYNOPSIS

Used internally by L<POEx::IRC::Client::Heavy::State>

=head1 DESCRIPTION

This class defines struct-like objects representing the state of a user
present on a L<POEx::IRC::Client::Heavy::State::Channel>.

These classes consume L<POEx::IRC::Client::Heavy::Role::Clonable>.

See L<POEx::IRC:Client::Heavy::State>

=head2 prefixes

A L<Data::Perl::Collection::Array> containing currently-visible status
prefixes for the present user.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=begin Pod::Coverage

new

=end Pod::Coverage

=cut
