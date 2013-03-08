package POEx::IRC::Client::Heavy::State::Channel;
use strictures 1;
use Carp;

use Moo;
use MooX::Types::MooseLike::Base ':all';
use namespace::clean;

has name => (
  required => 1,
  is       => 'ro',
);

has present => (
  is      => 'ro',
  isa     => sub {
    ref $_[0] eq 'HASH' or confess "$_[0] is not a HASH"
  },
  default => sub { +{} },
);

sub userlist {
  keys $_[0]->present
}

has topic => (
  is  => 'ro',
  isa => HasMethods[qw/ topic set_at set_by /],
  predicate => 'has_topic',
  writer    => 'set_topic',
);


1;

=pod

=head1 NAME

POEx::IRC::Client::Heavy::State::Channel

=head1 SYNOPSIS

Used internally by L<POEx::IRC::Client::Heavy::State>

=head1 DESCRIPTION

This class defines struct-like objects representing IRC channels for
L<POEx::IRC::Client::Heavy>.

See L<POEx::IRC::Client::Heavy::State>.

=head2 name

Returns the channel's name (as we saw it at join-time).

=head2 present

A HASH mapping currently-present users to their status prefixes, if any.

=head2 userlist

Returns the list of keys in the L</present> HASH.

=head2 topic

The L<POEx::IRC::Client::Heavy::State::Topic> object representing the current topic.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
