#!/usr/bin/perl

use Modern::Perl;
use Test::More;

my @timeEntries = (
    {
        comment => 'Normal same day worklogs on time',
        spent_on => '2016-03-15',
        created_on => '2016-03-15 16:01:22',
        hours => '2.5',
    },
    {
        comment => 'Normal same day worklogs on time',
        spent_on => '2016-03-15',
        created_on => '2016-03-15 11:02:33',
        hours => '3.11',
    },
    {
        comment => 'Normal same day worklogs on time',
        spent_on => '2016-03-15',
        created_on => '2016-03-15 08:00:00',
        hours => '0.1',
    },
    {
        comment => 'Same day worklogs with next day followups',
        spent_on => '2016-03-14',
        created_on => '2016-03-15 15:45:11',
        hours => '2',
    },
    {
        comment => 'Same day worklogs with next day followups',
        spent_on => '2016-03-14',
        created_on => '2016-03-15 15:48:31',
        hours => '3.05',
    },
    {
        comment => 'Same day worklogs with next day followups',
        spent_on => '2016-03-14',
        created_on => '2016-03-14 13:15:00',
        hours => '4.22',
    },
    {
        comment => 'Next day followup',
        spent_on => '2016-03-13',
        created_on => '2016-03-14 09:13:24',
        hours => '7.25',
    },
    {
        comment => 'Advance holiday logging',
        spent_on => '2016-03-20',
        created_on => '2016-03-15 15:18:01',
        hours => '7.25',
    },
);


require WorkDays;

subtest "bukkakeBuckets", \&bukkakeBuckets;
sub bukkakeBuckets {
    my $wd = WorkDays->new();
    my $buckets = $wd->_bukkakeBuckets(\@timeEntries);

    is($buckets->{'2016-03-15'}->[0]->{spent_on},
       '2016-03-15',
       'bukkakeBuckets: 1');
    is($buckets->{'2016-03-15'}->[1]->{spent_on},
       '2016-03-15',
       'bukkakeBuckets: 2');
    is($buckets->{'2016-03-15'}->[2]->{spent_on},
       '2016-03-15',
       'bukkakeBuckets: 3');
    is($buckets->{'2016-03-15'}->[3]->{spent_on},
       undef,
       'bukkakeBuckets: 4');
    is($buckets->{'2016-03-13'}->[0]->{hours},
       7.25,
       'bukkakeBuckets: 5');
    is($buckets->{'2016-03-20'}->[0]->{hours},
       7.25,
       'bukkakeBuckets: 6');
    is($buckets->{''},
       undef,
       'bukkakeBuckets: 7');
}

subtest "getDayAttributesFromBucket", \&_getDayAttributesFromBucket;
sub _getDayAttributesFromBucket {
    my ($day, $spent_on, $startTime, $startHours, $endTime, $hours, $wd, $buckets);
    $wd = WorkDays->new();
    $buckets = $wd->_bukkakeBuckets(\@timeEntries);

    $day = '2016-03-15';
    ($spent_on, $startTime, $startHours, $endTime, $hours) = $wd->_getDayAttributesFromBucket($day, $buckets->{$day});
    is($spent_on,     $day,             "getDayAttributesFromBucket 1");
    is("$startTime",  $day.'T08:00:00', "getDayAttributesFromBucket 2");
    is_deeply([$startHours->in_units('hours', 'minutes', 'seconds')],
              [0,6,0],                  "getDayAttributesFromBucket 3");
    is("$endTime",    $day.'T16:01:22', "getDayAttributesFromBucket 4");
    is_deeply([$hours->in_units('hours', 'minutes', 'seconds')],
              [5,42.6,0],               "getDayAttributesFromBucket 5");

    $day = '2016-03-14';
    ($spent_on, $startTime, $startHours, $endTime, $hours) = $wd->_getDayAttributesFromBucket($day, $buckets->{$day});
    is($spent_on,    $day,              "getDayAttributesFromBucket 6");
    is("$startTime", $day.'T13:15:00',  "getDayAttributesFromBucket 7");
    is_deeply([$startHours->in_units('hours', 'minutes', 'seconds')],
              [4,13.2,0],                  "getDayAttributesFromBucket 8");
    is("$endTime",   $day.'T13:15:00',  "getDayAttributesFromBucket 9");
    is_deeply([$hours->in_units('hours', 'minutes', 'seconds')],
              [9,16.2,0],               "getDayAttributesFromBucket 10");

    $day = '2016-03-13';
    ($spent_on, $startTime, $startHours, $endTime, $hours) = $wd->_getDayAttributesFromBucket($day, $buckets->{$day});
    is($spent_on,   $day,               "getDayAttributesFromBucket 11");
    is($startTime,  undef,              "getDayAttributesFromBucket 12");
    is($startHours, undef,              "getDayAttributesFromBucket 13");
    is($endTime,    undef,              "getDayAttributesFromBucket 14");
    is_deeply([$hours->in_units('hours', 'minutes', 'seconds')],
              [7,15,0],                 "getDayAttributesFromBucket 15");

    $day = '2016-03-20';
    ($spent_on, $startTime, $startHours, $endTime, $hours) = $wd->_getDayAttributesFromBucket($day, $buckets->{$day});
    is($spent_on,   $day,               "getDayAttributesFromBucket 16");
    is($startTime,  undef,              "getDayAttributesFromBucket 17");
    is($startHours, undef,              "getDayAttributesFromBucket 18");
    is($endTime,    undef,              "getDayAttributesFromBucket 19");
    is_deeply([$hours->in_units('hours', 'minutes', 'seconds')],
              [7,15,0],                 "getDayAttributesFromBucket 20");
}

subtest "calculateDayAttributes", \&calculateDayAttributes;
sub calculateDayAttributes {
    my ($wd, $buckets, $day, $a);
    $wd = WorkDays->new();
    $buckets = $wd->_bukkakeBuckets(\@timeEntries);

    $day = '2016-03-15';
    $a = $wd->_calculateDayAttributes(  $wd->_getDayAttributesFromBucket($day, $buckets->{$day})  );
    is($a->{spent_on},       $day,             "calculateDayAttributes 1");
    is($a->{start}->iso8601, $day.'T07:54:00', "calculateDayAttributes 2");
    is($a->{end}->iso8601,   $day.'T16:01:22', "calculateDayAttributes 3");
    is_deeply([$a->{break}->in_units('hours', 'minutes', 'seconds')],
              [2,24.4,22],                     "calculateDayAttributes 4");
    is_deeply([$a->{hours}->in_units('hours', 'minutes', 'seconds')],
              [5,42.6,0],                      "calculateDayAttributes 5");

    $day = '2016-03-14';
    $a = $wd->_calculateDayAttributes(  $wd->_getDayAttributesFromBucket($day, $buckets->{$day})  );
    is($a->{spent_on},       $day,             "calculateDayAttributes 6");
    is($a->{start}->iso8601, $day.'T09:01:48', "calculateDayAttributes 7");
    is($a->{end}->iso8601,   $day.'T18:18:00', "calculateDayAttributes 8");
    is_deeply([$a->{break}->in_units('hours', 'minutes', 'seconds')],
              [0,0,0],                         "calculateDayAttributes 9");
    is_deeply([$a->{hours}->in_units('hours', 'minutes', 'seconds')],
              [9,16.2,0],                      "calculateDayAttributes 10");

    $day = '2016-03-13';
    $a = $wd->_calculateDayAttributes(  $wd->_getDayAttributesFromBucket($day, $buckets->{$day})  );
    is($a->{spent_on},       $day,             "calculateDayAttributes 11");
    is($a->{start}->iso8601, $day.'T08:00:00', "calculateDayAttributes 12");
    is($a->{end}->iso8601,   $day.'T15:15:00', "calculateDayAttributes 13");
    is_deeply([$a->{break}->in_units('hours', 'minutes', 'seconds')],
              [0,0,0],                         "calculateDayAttributes 14");
    is_deeply([$a->{hours}->in_units('hours', 'minutes', 'seconds')],
              [7,15,0],                        "calculateDayAttributes 15");

    $day = '2016-03-20';
    $a = $wd->_calculateDayAttributes(  $wd->_getDayAttributesFromBucket($day, $buckets->{$day})  );
    is($a->{spent_on},       $day,             "calculateDayAttributes 16");
    is($a->{start}->iso8601, $day.'T08:00:00', "calculateDayAttributes 17");
    is($a->{end}->iso8601,   $day.'T15:15:00', "calculateDayAttributes 18");
    is_deeply([$a->{break}->in_units('hours', 'minutes', 'seconds')],
              [0,0,0],                         "calculateDayAttributes 19");
    is_deeply([$a->{hours}->in_units('hours', 'minutes', 'seconds')],
              [7,15,0],                        "calculateDayAttributes 20");
}

subtest "createDaysFromTimeEntries()", \&createDaysFromTimeEntries;
sub createDaysFromTimeEntries {
    my ($wd, $d);
    $wd = WorkDays->new();
    $wd->createDaysFromTimeEntries(\@timeEntries);

    $d = $wd->days->{'2016-03-15'};
    is($d->start->iso8601,
       '2016-03-15T07:54:00',
       'Normal same day worklogs on time: start');
    is($d->end->iso8601,
       '2016-03-15T16:01:22',
       'Normal same day worklogs on time: end');
    is(join(':', $d->break->in_units('hours', 'minutes')),
       '2:24.4',
       'Normal same day worklogs on time: break');
    is(join(':', $d->hours->in_units('hours', 'minutes')),
       '5:42.6',
       'Normal same day worklogs on time: hours');

    $d = $wd->days->{'2016-03-20'};
    is($d->start->iso8601,
       '2016-03-20T08:00:00',
       'Advance holiday logging: start');
    is($d->end->iso8601,
       '2016-03-20T15:15:00',
       'Advance holiday logging: end');
    is(join(':', $d->break->in_units('hours', 'minutes')),
       '0:0',
       'Advance holiday logging: break');
    is(join(':', $d->hours->in_units('hours', 'minutes')),
       '7:15',
       'Advance holiday logging: hours');
}