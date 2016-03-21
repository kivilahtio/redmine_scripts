#!/usr/bin/perl

use Modern::Perl;
use DBI;

use Util::DB;

my $workDays = WorkDays->new();
$workDays->createDaysFromRedmine( Util::DB::getTimeEntries(1) );
$workDays->toString();
$workDays->toCsv();
