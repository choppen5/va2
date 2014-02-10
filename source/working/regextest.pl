#! perl -w
# TestPerlprocdata.pl 

use Perlprocdata;

my $pp = new Perlprocdata;

my @x;
for (0..5) {
	$pp->printProcessMemInfoShort; # probe
	# gobble some memory
	push @x, 1 for (0...100000);
	sleep 1;
}

# free the memory (to perl, not to the OS)
@x = ();


for (0..10) {
	$pp->printProcessMemInfoShort;  # probe
	# gobble some more memory
	push @x, 1 for (0...100000);
	sleep 1;
}

# free the memory (to perl, not to the OS)
@x = ();


__END__

           [Name] [PageFaults/s]    [PeakWS]        [WS]

         perl.exe            841     3436544     3436544
         perl.exe           1366     5586944     5586944
         perl.exe           1894     7753728     7753728
         perl.exe           2694    11034624    11034624
         perl.exe           2945    12062720    12062720
         perl.exe           3344    13697024    13697024
         perl.exe           4545    18620416    18620416
         perl.exe           4545    18620416    18620416
         perl.exe           4545    18620416    18620416
         perl.exe           4545    18620416    18620416
         perl.exe           4545    18620416    18620416
         perl.exe           4545    18620416    18620416
         perl.exe           4545    18620416    18620416
         perl.exe           4647    19038208    19038208
         perl.exe           5046    20676608    20676608
         perl.exe           5444    22306816    22306816
         perl.exe           5844    23949312    23949312

##</code><code>##

#! perl -w
# Perlprocdata.pm by Rudif@bluemail.ch

use strict;

package Perlprocdata;


# uses Win32::IProcess by Amine Moulay Ramdane                
# from website: http://www.generation.net/~aminer/Perl/ 


use Win32::IProcess qw(
	PROCESS_QUERY_INFORMATION PROCESS_VM_READ INHERITED INHERITED DIGITAL NOPATH
);  


#----------------------------------------------------------
sub new {
    my ($class, %args) = @_;
    my $self = {};
    bless $self, $class;

	my $obj = $self->{obj} = new Win32::IProcess || die "Can not create an IProcess object..\n";

	my @EnumInfo;
	$obj->EnumProcesses(\@EnumInfo);

	my $size=scalar(@EnumInfo);

	for(my $j=0;$j<$size;$j++) {
		if ($EnumInfo[$j]->{ProcessName} =~ /perl/i) {
			$self->{EnumInfo} = $EnumInfo[$j];
			my $Info;
			$obj->GetProcessMemInfo($EnumInfo[$j]->{ProcessId},\$Info);
			$self->{Info} = $Info;
			my @data = (
				$EnumInfo[$j]->{ProcessName},
				$Info->{PageFaultCount},
				$Info->{PeakWorkingSetSize},
				$Info->{WorkingSetSize},
				$Info->{QuotaPagedPoolUsage},
				$Info->{QuotaNonPagedPoolUsage},
				$Info->{PagefileUsage});
		}
	}

    return $self;
}

#----------------------------------------------------------
sub getProcessMemInfo {
	my $self = shift;
	$self->{obj}->GetProcessMemInfo($self->{EnumInfo}{ProcessId},\$self->{Info});
}

#----------------------------------------------------------
sub printProcessMemInfoShort {
	my $self = shift;
	$self->getProcessMemInfo;
	printf("\n\n%17.15s%15.14s%12.11s%12.11s\n\n",
            "[Name]","[PageFaults/s]", "[PeakWS]","[WS]")
            unless $self->{printed}++;
	printf("%17.15s%15.14s%12.11s%12.11s\n",
		$self->{EnumInfo}{ProcessName},
		$self->{Info}{PageFaultCount},
		$self->{Info}{PeakWorkingSetSize},
		$self->{Info}{WorkingSetSize});
}

1;

__END__

