package POEx::IRC::Client::Heavy::State::Topic;
use strictures 1;
use Carp;
use Role::Tiny::With;

use POEx::IRC::Client::Heavy::State::Struct;
with 'POEx::IRC::Client::Heavy::Role::Clonable';

has_ro topic  => ();
has_ro set_by => ();
has_ro set_at => ( default => 0 );

sub new {
  my ($cls, %params) = @_;
  my $self = +{%params};
  my @required = qw/ topic set_by /;
  for my $opt (@required) {
    confess "Missing required param $opt"
      unless defined $self->{$opt};
  }
}

1;

=pod

=head1 NAME

POEx::IRC::Client::Heavy::State::Topic

=head1 SYNOPSIS

Used internally by L<POEx::IRC::Client::Heavy::State>

=head1 DESCRIPTION

This class defines lightweight struct-like objects representing channel
topics for L<POEx::IRC::Client::Heavy>.

See L<POEx::IRC::Client::Heavy::State>.

=head2 topic

Returns the current topic string.

=head2 set_at

Returns the topic timestamp (or 0)

=head2 set_by

Returns the topic's setter.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut