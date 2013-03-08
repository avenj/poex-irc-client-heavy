use Test::More;
use strict; use warnings FATAL => 'all';

{
  package
  TestAbleStruct;
  use strict; use warnings FATAL => 'all';
  use POEx::IRC::Client::Heavy::State::Struct;
  use Role::Tiny::With;
  with 'POEx::IRC::Client::Heavy::Role::Clonable';

  has_ro readable => ();
  has_ro readable_def => ( default => 'abc' );
  has_ro readable_def_code => (
    default => sub { $_[0]->readable_def . 'def' },
  );

  sub new {
    my ($c, %prm) = @_;
    bless +{%prm}, $c
  }
}

my $struct = TestAbleStruct->new(
  readable => 'snacks',
);

cmp_ok( $struct->readable, 'eq', 'snacks',
  'readable init ok'
);
cmp_ok( $struct->readable_def, 'eq', 'abc',
  'readable_def init ok'
);
cmp_ok( $struct->readable_def_code, 'eq', 'abcdef',
  'readable_def_code init ok'
);

my $newst = $struct->new_with_params(
  readable_def => 'cake',
  readable     => 'pie',
);

cmp_ok( $newst, '!=', $struct, 'new struct built' );

cmp_ok( $newst->readable, 'eq', 'pie',
  'new struct readable() ok'
);
cmp_ok( $newst->readable_def, 'eq', 'cake',
  'new struct readable_def() ok'
);
cmp_ok( $newst->readable_def_code, 'eq', 'abcdef',
  'new struct readable_def_code() ok'
);

my $cloned;
ok($cloned = $newst->clone, 'clone()' );
isa_ok( $cloned, 'TestAbleStruct' );
cmp_ok( $cloned, '!=', $newst, 'struct was cloned' );
cmp_ok( $cloned->readable, 'eq', 'pie', 
  'cloned readable() ok' 
);

done_testing;
