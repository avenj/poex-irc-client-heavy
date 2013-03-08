package POEx::IRC::Client::Heavy::State::Topic;
use strictures 1;
use Carp;

use Moo;

has topic => (
  required  => 1,
  is        => 'ro',
);

has set_at => (
  is        => 'ro',
  default   => sub { 0 },
);

has set_by => (
  required  => 1,
  is        => 'ro',
);

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
