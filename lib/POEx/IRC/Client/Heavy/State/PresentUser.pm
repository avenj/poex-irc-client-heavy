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

=pod

=for Pod::Coverage new

=cut

sub new {
  my ($cls, %params) = @_;
  bless +{%params}, $cls
}

1;
