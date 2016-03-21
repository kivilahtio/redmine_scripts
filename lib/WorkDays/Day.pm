package WorkDays::Day;

use Moose;
use namespace::autoclean;

has 'start' => (is => 'ro', isa => 'DateTime', required => 0, writer => "_set_start");
has 'end' => (is => 'ro', isa => 'DateTime', required => 0, writer => "_set_end");
has 'break' => (is => 'ro', isa => 'DateTime::Duration', required => 0, writer => "_set_break");
has 'hours' => (is => 'ro', isa => 'DateTime::Duration', required => 1);

__PACKAGE__->meta->make_immutable;

1;
