use Test::More;
use Test::Exception;
use strict; use warnings FATAL => 'all';

use_ok( 'POEx::IRC::Client::Heavy::State::Channel' );
use_ok( 'POEx::IRC::Client::Heavy::State::Topic' );

my $chan = POEx::IRC::Client::Heavy::State::Channel->new(
  name => '#mychan',
);

cmp_ok( $chan->name, 'eq', '#mychan', 'name() ok' );
ok( ! defined $chan->topic, 'no topic() set' );
is_deeply( $chan->present, +{}, 'present() is empty' );


my $topic = POEx::IRC::Client::Heavy::State::Topic->new(
  topic  => 'My topic',
  set_by => 'avenj',
);

cmp_ok( $topic->topic, 'eq', 'My topic', 'topic() ok' );
cmp_ok( $topic->set_by, 'eq', 'avenj', 'set_by() ok' );
cmp_ok( $topic->set_at, 'eq', '0', 'set_at() defaulted to 0' );

my $with_topic = $chan->new_with_params(
  topic => $topic->new_with_params(set_at => 1234),
);
cmp_ok( $with_topic->name, 'eq', '#mychan', 'name() preserved' );
cmp_ok( $with_topic->topic->topic, 'eq', 'My topic', 'topic->topic() ok' );
cmp_ok( $with_topic->topic->set_at, 'eq', '1234', 'topic->set_at() ok' );


dies_ok(sub {
    POEx::IRC::Client::Heavy::State::Channel->new
  },
  'dies with missing required params'
);

dies_ok(sub {
    $with_topic->new_with_params(topic => 'abc')
  },
  'dies with invalid topic obj'
);


done_testing;