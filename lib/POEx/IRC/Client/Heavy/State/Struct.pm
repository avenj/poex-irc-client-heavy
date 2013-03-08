package POEx::IRC::Client::Heavy::State::Struct;
use strictures 1;
use Carp;

use Exporter 'import';
our @EXPORT = 'has_a';

## FIXME custom import method to install constructors instead?
##  - push ourselves to targets ISA
##  - collect required => 1 attribs
##  - add lazy?

sub has_ro {
  my ($acc, %params) = @_;

  no strict 'refs';
  if (defined $params{default}) {
    my $default = $params{default};
    *{ caller().'::'.$acc } = sub {
      confess "Read-only attribute $acc" if defined $_[1];
      $_[0]->{$acc} //= $default
    }
  } else {
    *{ caller().'::'.$acc } = sub {
      confess "Read-only attribute $acc" if defined $_[1];
      $_[0]->{$acc}
    }
  }
}

1;

