use Test::More;
use Test::Exception;
use strict; use warnings FATAL => 'all';

{
  package
  TestAbleStruct;
  use strict; use warnings FATAL => 'all';
  use POEx::IRC::Client::Heavy::State::Struct;

  has_ro readable => ();
  has_ro readable_def => ( default => 'abc' );
  has_ro readable_def_code => (
    default => sub { $_[0]->readable_def . 'def' },
  );

  has_rw writable => ();
  has_rw writable_def => ( default => 'foo' );
  has_rw writable_def_code => (
    default => sub { $_[0]->writable_def . 'bar' },
  );

  sub new {
    my ($c, %prm) = @_;
    bless +{%prm}, $c
  }
}

## Basic readers.
my $struct = TestAbleStruct->new;
ok( !$struct->readable, 'empty readable ok' );
cmp_ok( $struct->readable_def, 'eq', 'abc',
  'readable with default ok'
);
cmp_ok( $struct->readable_def_code, 'eq', 'abcdef',
  'readable with coderef default ok'
);

## Initialized readers.
undef $struct;
$struct = TestAbleStruct->new(
  readable => 'snacks',
  readable_def => 'xyz',
);
cmp_ok( $struct->readable, 'eq', 'snacks',
  'filled readable ok'
);
cmp_ok( $struct->readable_def_code, 'eq', 'xyzdef',
  'readable lazy default ok'
);

## Basic writers.
undef $struct;
$struct = TestAbleStruct->new;
ok( !$struct->writable, 'empty writable ok' );
cmp_ok( $struct->writable_def, 'eq', 'foo',
  'writable with default ok'
);
cmp_ok( $struct->writable_def_code, 'eq', 'foobar',
  'writable with coderef default ok'
);
ok( $struct->writable('abc'), 'set writable() ok' );
cmp_ok( $struct->writable, 'eq', 'abc',
  'writable() was set'
);

## Initialized writers.
undef $struct;
$struct = TestAbleStruct->new(
  writable => 'cake',
);
$struct->writable_def('snack');
cmp_ok( $struct->writable, 'eq', 'cake',
  'filled writable ok'
);
cmp_ok( $struct->writable_def, 'eq', 'snack',
  'set writable_def ok'
);
cmp_ok( $struct->writable_def_code, 'eq', 'snackbar',
  'writable lazy default ok'
);

## Exceptions.
dies_ok(sub { $struct->readable('abc') }, 'writing to ro dies' );
dies_ok(sub { $struct->writable('a', 'b') }, 'incorrect args to rw dies' );

done_testing;
