#!/usr/bin/perl

use Win32::ODBC;
use sqlanalyze;

use vaodbc;

my $sql = "sp_spaceused"; #sql server stored procedure


my $datasession = vaodbc->newodbcsession("VADMIN21","sa","");

my $siebeldata = vaodbc->createfromdsn($datasession,'siebeldata');
my $dbsize = sqlanalyze->returnsinglevalue($sql, $siebeldata, "database_size");

if ($dbsize =~ /(\d+\.\d+) MB/) {
	$retval = $1;	#$1 is the captured db size from a string
}

print $retval;
