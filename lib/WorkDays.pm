package WorkDays;

use Moose;
use Function::Parameters;

use DateTime;
use DateTime::Duration;
use DateTime::Format::MySQL;

use WorkDays::Day;

has 'days' => (is => 'ro', isa => 'HashRef', default => sub{ {} });

method createDaysFromTimeEntries(ArrayRef $timeEntries) {

    my $timeEntryBuckets = $self->_bukkakeBuckets($timeEntries);

    while(my ($spent_on, $bucket) = each(%$timeEntryBuckets)) {
        $self->addDay(
            $self->_calculateDayAttributes(
                $self->_getDayAttributesFromBucket($spent_on, $bucket)
            )
        );
    }
}

method _bukkakeBuckets(ArrayRef $timeEntries) {
    my %timeEntryBuckets;
    foreach my $te (@$timeEntries) {
        $timeEntryBuckets{ $te->{spent_on} } = [] unless $timeEntryBuckets{ $te->{spent_on} };
        push @{$timeEntryBuckets{ $te->{spent_on} }}, $te;
    }
    return \%timeEntryBuckets;
}

method _getDayAttributesFromBucket($spent_on, ArrayRef $bucket) {
    ##Find min start time and max end time for the given day
    my ($startTime, $endTime);
    ##Store the hours spent on the first worklog entry, so we can subtract it from the first entry recording time to get the real start of the day.
    my $startHours;
    ##Sum the hours spent on the given day
    my $hours = DateTime::Duration->new();

    foreach my $te (@$bucket) {
        my $newCreOn;
        if (isSameDateString($te->{created_on}, $te->{spent_on})) {
            $newCreOn = DateTime::Format::MySQL->parse_datetime( $te->{created_on} );
        }
        my $newHours = _hoursToDuration($te->{hours});

        if ((not($startTime) && $newCreOn) ||
            ($newCreOn && DateTime->compare($newCreOn, $startTime) == -1)) { #created_on < $startTime
            $startTime = $newCreOn;
            $startHours = _hoursToDuration($te->{hours});
        }
        if ((not($endTime) && $newCreOn) ||
            ($newCreOn && DateTime->compare($newCreOn, $endTime) == 1)) { #created_on > $endTime
            $endTime = $newCreOn;
        }

        $hours->add_duration( $newHours );
    }
    return ($spent_on, $startTime, $startHours, $endTime, $hours);
}

method _calculateDayAttributes($spent_on, DateTime|Undef $start, DateTime::Duration|Undef $firstWorkTimeDuration, DateTime|Undef $end, DateTime::Duration $dayDuration) {

    if ($start) {
        $start->subtract_duration( $firstWorkTimeDuration );
    }
    else {
        $start = DateTime::Format::MySQL->parse_datetime($spent_on." 00:00:00")->set_hour(8)->set_minute(0)->set_second(0);
    }
    if ($end) {
        #ok
    }
    else {
        $end = $start->clone()->add_duration($dayDuration);
    }

    my $break = $end->clone()->subtract_datetime($start)->subtract_duration( $dayDuration );

    #if we have negative break duration, simply treat it as zero
    if (DateTime::Duration->compare($break, DateTime::Duration->new()) == -1) { #break < 0
        $break = DateTime::Duration->new();
    }
    #If our day ends sooner than what hours we have logged, extend the day.
    my $expectedEndTime = $start->clone()->add_duration( $dayDuration );
    if (DateTime->compare($end, $expectedEndTime) == -1) {
        $end = $expectedEndTime;
    }

    return {
        spent_on => $spent_on,
        start => $start,
        end   => $end,
        break => $break,
        hours => $dayDuration,
    };
}
method addDay(HashRef $dayParams) {
    $self->days->{ $dayParams->{spent_on} } = WorkDays::Day->new($dayParams);
}
sub toCsv {
    my ($self) = @_;

    my $csv = Text::CSV->new or die "Cannot use CSV: ".Text::CSV->error_diag ();
    $csv->eol("\n");
    open my $fh, ">:encoding(utf8)", "workTime.csv" or die "workTime.csv: $!";

    foreach my $ymd (sort keys %{$self->{days}}) {
        my $day = $self->{days}->{$ymd};
        my @row = (
            $ymd,
            $day->{start}->hms,
            $day->{end}->hms,
            sprintf("%02d:%02d:%02d", $day->{break}->in_units('hours', 'minutes', 'seconds')),
            sprintf("%02d:%02d:%02d", $day->{hours}->in_units('hours', 'minutes', 'seconds')),
        );
        $csv->print($fh, \@row);
    }

    close $fh or die "workTime.csv: $!";
}

sub toString {
    my ($self) = @_;

    foreach my $ymd (sort keys %{$self->{days}}) {
        my $day = $self->{days}->{$ymd};
        printf("%s %s %s %02d:%02d %02d:%02d \n",
               $ymd,
               $day->{start}->hms,
               $day->{end}->hms,
               $day->{break}->in_units('hours', 'minutes'),
               $day->{hours}->in_units('hours', 'minutes')
        );
    }
}

sub _hoursToDuration {
    my ($hours) = @_;

    my ($h, $m);
    if ($hours =~ /^(\d+)[.,]?(\d*)$/) {
        $h = $1 || 0;
        $m = ($2 && length($2) == 1) ? $2*10 : $2;
        $m = $m/100*60 if $m;
        $m = 0 unless $m;
    }
    else {
        confess "Couldn't parse '$hours'";
    }

    my $duration = DateTime::Duration->new( hours => $h, minutes => $m );
    return $duration;
}

sub isSameDate {
    my ($dt1, $dt2) = @_;
    if ($dt1->ymd eq $dt2->ymd) {
        return 1;
    }
    return 0;
}

sub isSameDateString {
    my ($dt1, $dt2) = @_;
    $dt1 = substr($dt1,0,10);
    $dt2 = substr($dt2,0,10);
    if ($dt1 eq $dt2) {
        return 1;
    }
    return 0;
}

1;
