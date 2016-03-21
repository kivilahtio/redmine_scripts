#!/usr/bin/perl

use Modern::Perl;
use Test::More;

use DateTime;
use DateTime::Duration;
use DateTime::Format::ISO8601;

require WorkDays::Day;

my $startTimeStr = '2016-03-12T05:45:45';
my $endTimeStr   = '2016-03-12T18:33:51';
my %break = (hours => 5, minutes => 33, seconds => 12);
my %hours = (hours => 4, minutes => 23, seconds => 1);
my $wd = WorkDays::Day->new({
                    start => DateTime::Format::ISO8601->parse_datetime($startTimeStr),
                    end   => DateTime::Format::ISO8601->parse_datetime( $endTimeStr ),
                    break => DateTime::Duration->new(%break),
                    hours => DateTime::Duration->new(%hours),
});
is($wd->start->iso8601,
   DateTime::Format::ISO8601->parse_datetime($startTimeStr)->iso8601,
   "start");
is($wd->end->iso8601,
   DateTime::Format::ISO8601->parse_datetime($endTimeStr)->iso8601,
   "end");

done_testing;