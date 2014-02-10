#!c:/perl/bin/perl.exe
# This is a test scrip
use Win32::Process::Info;
use warnings;
#use strict;

my  $pi = Win32::Process::Info->new (undef,'WMI');
my @process_information  = $pi->GetProcInfo(); ## 4488 is pid of a

foreach  $info (@process_information) {
		foreach my $key (keys %{$info}) {
							if ($key eq "WorkingSetSize") {
									my $value = ${$info}{$key}/1024;
									print "$key:=>$value \n"
							}

		}
}

