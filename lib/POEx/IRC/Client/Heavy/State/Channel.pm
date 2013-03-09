package POEx::IRC::Client::Heavy::State::Channel;
use strictures 1;
use Carp;
use Scalar::Util 'blessed';

use Role::Tiny::With;
use POEx::IRC::Client::Heavy::State::Struct;
with 'POEx::IRC::Client::Heavy::Role::Clonable';

use namespace::clean;

has_ro topic => ();
has_ro name  => ();
has_ro present => ( default => +{} );

=pod

=for Pod::Coverage new

=cut

sub new {
  my ($cls, %params) = @_;

  confess "Expected a 'name' parameter" unless defined $params{name};

  if (defined $params{topic}) {
    my $topic = $params{topic};
    confess "Expected blessed object but got $topic"
      unless blessed $topic;
    for my $meth (qw/ topic set_at set_by /) {
      confess "$topic missing required method $meth"
        unless $topic->can($meth)
    }
  }

  bless +{%params}, $cls
}

sub userlist {
  keys %{ $_[0]->present }
}

1;

=pod

=head1 NAME

POEx::IRC::Client::Heavy::State::Channel

=head1 SYNOPSIS

Used internally by L<POEx::IRC::Client::Heavy::State>

=head1 DESCRIPTION

This class defines struct-like objects representing the state of an 
IRC channel for L<POEx::IRC::Client::Heavy>.

These classes consume L<POEx::IRC::Client::Heavy::Role::Clonable>.

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
