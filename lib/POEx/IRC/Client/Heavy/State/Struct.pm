package POEx::IRC::Client::Heavy::State::Struct;
use 5.10.1;
use strictures 1;
use Carp;

use Exporter 'import';
our @EXPORT = 'has_ro';

sub has_ro {
  my ($acc, %params) = @_;
  no strict 'refs';
  if (defined $params{default}) {

    my $default = ref $params{default} eq 'CODE' ?
      $params{default}->() : $params{default};

    *{ caller().'::'.$acc } = sub {
      confess "Read-only attribute $acc" if @_ > 1;
      $_[0]->{$acc} //= $default
    }

  } else {

    *{ caller().'::'.$acc } = sub {
      confess "Read-only attribute $acc" if @_ > 1;
      $_[0]->{$acc}
    }

  }
}

sub has_rw {
  my ($acc, %params) = @_;
  no strict 'refs';
  if (defined $params{default}) {

    my $default = ref $params{default} eq 'CODE' ?
      $params{default}->() : $params{default};

    *{ caller().'::'.$acc } = sub {
      confess "Too many arguments passed to writer for $acc"
        if @_ > 2;
      return $_[0]->{$acc} = $_[1] if @_ > 1;
      $_[0]->{$acc} //= $default
    }

  } else {

    *{ caller().'::'.$acc } = sub {
      confess "Too many arguments passed to writer for $acc"
        if @_ > 2;
      return $_[0]->{$acc} = $_[1] if @_ > 1;
      $_[0]->{$acc}
    }

  }
}

1;

=pod

=head1 NAME

POEx::IRC::Client::Heavy::State::Struct - Simple accessors for state structs

=head1 SYNOPSIS

  package MyStruct;
  use POEx::IRC::Client::Heavy::State::Struct;

  # Mutable:
  has_rw objects => ();

  # Immutable:
  has_ro things => ();
  has_ro array  => ( default => [] );

  # Basic minimalist example constructor:
  sub new {
    my ($cls, %params) = @_;

    die "Missing required param 'things'" 
      unless defined $params{things};

    my $self = +{%params};
    bless $self, $cls
  }

  package main;
  my $struct = MyStruct->new( things => 'stuff' );
  # 'stuff':
  $struct->things;
  # default:
  push @{ $struct->array }, qw/ a b c /;
  # rw attribute:
  $struct->objects( \@objs );

=head1 DESCRIPTION

Simple accessor generation for L<POEx::IRC::Client::Heavy::State> structs.

No constructors are created and the caller's inheritance is left untouched.

All defaults are lazy. There are no fancy features.

=head2 Exported

=head3 has_ro

  has_ro 'stuff';

Creates a read-only attribute. A B<default> can optionally be specified:

  has_ro stuff => ( default => 'things' );

=head3 has_rw

Creates a readable/writable attribute. 

Uses the same syntax as L</has_ro>.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
