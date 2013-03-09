use Test::More;
use strict; use warnings FATAL => 'all';

use_ok('POEx::IRC::Client::Heavy::State::PresentUser');

my $obj = new_ok( 'POEx::IRC::Client::Heavy::State::PresentUser' );
ok( $obj->prefixes, 'has prefixes()' );
ok( $obj->prefixes->push(qw/@ %/), 'prefixes->push() ok' );
cmp_ok( $obj->prefixes->all, '==', 2, 'prefixes->all() ok' );

done_testing;
