use Test::More;
use Test::Exception;
use strict; use warnings FATAL => 'all';

use_ok( 'POEx::IRC::Client::Heavy::State::User' );

my $user = POEx::IRC::Client::Heavy::State::User->new(
  nick => 'avenj',
  user => 'myuser',
  host => 'cobaltirc.org',
  realname => 'I like pie',
);

isa_ok( $user, 'POEx::IRC::Client::Heavy::State::User' );

cmp_ok( $user->nick, 'eq', 'avenj', 'nick() ok' );
cmp_ok( $user->user, 'eq', 'myuser', 'user() ok' );
cmp_ok( $user->host, 'eq', 'cobaltirc.org', 'host() ok' );
cmp_ok( $user->realname, 'eq', 'I like pie', 'realname() ok' );
cmp_ok( $user->is_away, 'eq', 0, 'is_away() is 0' );
cmp_ok( $user->is_oper, 'eq', 0, 'is_oper() is 0' );
ok( ! defined $user->account, 'no account() set' );

my $second = $user->new_with_params(
  is_away => 1,
  is_oper => 1,
);
cmp_ok( $second->nick, 'eq', 'avenj', 'new_with_params nick ok' );
cmp_ok( $second->is_away, 'eq', 1, 'new_with_params is_away ok' );
cmp_ok( $second->is_oper, 'eq', 1, 'new_with_params is_oper ok' );

dies_ok(sub {
    POEx::IRC::Client::Heavy::State::User->new(is_away => 1)
  },
  "missing required params dies"
);

done_testing;
