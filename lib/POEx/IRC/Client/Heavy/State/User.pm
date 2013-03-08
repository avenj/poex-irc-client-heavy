package POEx::IRC::Client::Heavy::State::User;
use strictures 1;
use Carp;

use Moo;
use MooX::Types::MooseLike::Base ':all';
use namespace::clean;

has account => (
  is  => 'ro',
);

has nick => (
  required  => 1,
  is        => 'ro',
);

has user => (
  required  => 1,
  is        => 'ro',
);

has host => (
  required  => 1,
  is        => 'ro',
);

has realname => (
  required  => 1,
  is        => 'ro',
);

has is_away => (
  is        => 'ro',
  default   => sub { 0 },
);

has is_oper => (
  is        => 'ro',
  default   => sub { 0 },
);

1;
