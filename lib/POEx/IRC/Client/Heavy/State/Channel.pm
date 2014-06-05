package POEx::IRC::Client::Heavy::State::Channel;

use Defaults::Modern;

use POEx::IRC::Client::Heavy::State::Topic;

use Moo; use MooX::late;

has name => (
  required  => 1,
  is        => 'ro',
  isa       => Str,
);

has present => (
  lazy      => 1,
  is        => 'ro',
  isa       => HashObj,
  coerce    => 1,
  builder   => sub { +{} },
);

has topic => (
  lazy      => 1,
  is        => 'ro',
  isa       => InstanceOf['POEx::IRC::Client::Heavy::State::Topic'],
  builder   => sub { POEx::IRC::Client::Heavy::State::Topic->new },
);


method userlist { $self->present->keys }

1;

=pod

=begin Pod::Coverage

new

=end Pod::Coverage

=head1 NAME

POEx::IRC::Client::Heavy::State::Channel

=head1 SYNOPSIS

Used internally by L<POEx::IRC::Client::Heavy::State>

=head1 DESCRIPTION

This class defines struct-like objects representing the state of an 
IRC channel for L<POEx::IRC::Client::Heavy>.

See L<POEx::IRC::Client::Heavy::State>.

=head2 name

Returns the channel's name (as we saw it at join-time).

=head2 present

A L<List::Objects::WithUtils::Hash> mapping currently-present users 
to their status prefixes, if any.

=head2 userlist

Returns the list of keys in the L</present> HASH as a
L<List::Objects::WithUtils::Array>.

=head2 topic

The L<POEx::IRC::Client::Heavy::State::Topic> object representing the current topic.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
