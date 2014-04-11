package POEx::IRC::Client::Heavy::State::Topic;
use Defaults::Modern;

use Role::Tiny::With;

use POEx::IRC::Client::Heavy::State::Struct;
with 'POEx::IRC::Client::Heavy::Role::Clonable';

use namespace::clean;

has_ro topic  => ( default => '' );
has_ro set_by => ( default => '' );
has_ro set_at => ( default => 0 );

=pod

=for Pod::Coverage new

=cut

sub new {
  my ($cls, %params) = @_;
  my @required = qw/ topic set_by /;
  for my $opt (@required) {
    confess "Missing required param $opt"
      unless defined $params{$opt};
  }
  bless +{%params}, $cls
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

These classes consume L<POEx::IRC::Client::Heavy::Role::Clonable>.

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
