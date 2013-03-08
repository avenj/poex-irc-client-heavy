package POEx::IRC::Client::Heavy::Role::Clonable;
use strictures 1;
use Carp;

use Scalar::Util 'blessed';
use Storable 'dclone';

use Role::Tiny;

use namespace::clean;

sub clone {
  dclone $_[0]
}

sub new_with_params {
  my ($self, %params) = @_;
  confess "new_with_params() should be called on an instanced object"
    unless blessed $self;
  my %cur = %{ $self->clone };
  @cur{keys %params} = values %params;
  ref($self)->new(%cur)
}

1;

=pod

=head1 NAME

POEx::IRC::Client::Heavy::Role::Clonable

=head1 SYNOPSIS

  package MyStruct;
  use Role::Tiny::With;
  use POEx::IRC::Client::Heavy::State::Struct;
  with 'POEx::IRC::Client::Heavy::Role::Clonable';

  has_ro 'things';
  has_ro 'stuff';

  sub new {
    my $class = shift;
    bless +{@_}, class
  }

  package main;
  my $struct = MyStruct->new(things => 'cake', stuff => 'snacks');
  my $cloned = $struct->clone;
  my $newstruct = $struct->new_with_params(things => 'pie');

=head1 DESCRIPTION

A L<Role::Tiny> role for conveniently building new objects from
L<POEx::IRC::Client::Heavy::State::Struct> immutable structs.

This is used internally by L<POEx::IRC::Client::Heavy>.

=head2 clone

Returns a cloned object via L<Storable/"dclone">.

=head2 new_with_params

Returns a new object with the specified parameters, retaining any
previously-known keys in the backing HASH.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
