package POEx::IRC::Client::Heavy::State::Struct;
use 5.10.1;
use strictures 1;
use Carp;

use Exporter 'import';
our @EXPORT = qw/
  has_ro
  has_rw 
/;

sub _gen_attr {
  my ($class, $type, $attr, %params) = @_;
  confess "Invalid attrib name $attr" unless $attr =~ /^[a-zA-Z_]\w*$/;

  my $default = $params{default};
  if (ref $default && ref $default ne 'CODE') {
    confess "Expected default => to be a CODE ref or simple scalar"
  }

  my $c = "package $class;\nsub $attr {\n";
  if ($type eq 'rw') {
    $c .= "  if (\@_ == 2) {\n";
    $c .= "    return \$_[0]->{'$attr'} = \$_[1];\n";
    $c .= "  }\n";
  } 
  if (defined $default) {
    $c .= "  return \$_[0]->{'$attr'} if exists \$_[0]->{'$attr'};\n"
        . "  return \$_[0]->{'$attr'} = "
        . ref $default eq 'CODE' ? '$default->($_[0]);' : '$default';
  }
  $c .= "  return \$_[0]->{'$attr'} \n}";

  warn "  -> inst $attr in $class\n$c\n\n" if $ENV{POEX_IRCCLI_HEAVY_DEBUG};
  no strict 'refs';
  confess "Failed in attrib creation ($class $attr): $@"
    unless eval "$c; 1";
}


sub has_ro {
  my $attr   = shift;
  my $caller = caller();
  _gen_attr($caller, 'ro', $attr, @_)
}

sub has_rw {
  my $attr = shift;
  my $caller = caller();
  _gen_attr($caller, 'rw', $attr, @_)
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
  $struct->objects( [ 'a', 'b' ] );

=head1 DESCRIPTION

Simple accessor generation for L<POEx::IRC::Client::Heavy::State> structs.

No constructors are created and the caller's inheritance is left untouched.

All defaults are lazy. There are no fancy features.

=head2 Exported

=head3 has_ro

  has_ro 'stuff';

Creates a read-only attribute. A B<default> can optionally be specified:

  has_ro stuff => ( default => 'things' );

The B<default> can be a coderef, in which case it is passed the '$self'
object.

=head3 has_rw

Creates a readable/writable attribute. 

Uses the same syntax as L</has_ro>.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
