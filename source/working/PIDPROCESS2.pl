use Win32::IProcess qw(
PROCESS_QUERY_INFORMATION PROCESS_VM_READ INHERITED INHERITED DIGITAL NOPATH
); 

use Win32::API;
use Getopt::Long;
use Array::Compare;
use vadmin::data1;
use strict;
use Log::Logger;

my $lh = new Log::Logger "siebparse.log" ;				# global log file
my $host = 'IBMT42';
my $debug = 1; 

#todo:
# 1. call other memory sub routine
# 2. change pid process so it inserts instead of only updating

my $datasession = vadmin::data1::odbcsess($debug,$lh,'VADMIN21','sa','sa') ;
my %prevrunning;
my $taskreset = 0;
my $pidcompare = Array::Compare->new;

# Define some contants
my $DWORD_SIZE = 4;
my $PROC_ARRAY_SIZE = 100;
my $MODULE_LIST_SIZE = 200;

# Define some Win32 API constants
my $PROCESS_QUERY_INFORMATION = 0x0400;
my $PROCESS_VM_READ = 0x0010;
my $OpenProcess = new Win32::API( 'kernel32.dll', 'OpenProcess', ['N','I','N'], 'N' ) || $lh->log_print("Can not openprocess");
my $CloseHandle = new Win32::API( 'kernel32.dll', 'CloseHandle', ['N'], 'I' ) || $lh->log_print("Can not openprocess");
my $GetProcessMemoryInfo = new Win32::API( 'psapi.dll', 'GetProcessMemoryInfo', ['N','P','N'], 'I' ) || $lh->log_print("Can not link GetProcessMemoryInfo()");




while (1) {
	my @runningpids = &printprocesses();
	sleep(1);
}



sub printprocesses {

	my (@EnumInfo,$i,$Info);	
	my @running;
	my $update;
	my $noupdate;
			
	my($obj)=new Win32::IProcess || $lh->log_print("Can not create an IProcess object..");
	$obj->EnumProcesses(\@EnumInfo);
	my $numprocs = scalar(@EnumInfo);
	print "numprocs = $numprocs\n";


	for($i=0;$i<$numprocs;$i++)
		{
			
			my $Hnd;
			my $TimeInfo;
			#initialize variables
			my $procname;
			my $pid;
			my $cputime; #combine cpu user and kerenel time
			my $usersecs;
			my $kernelsecs;
			my $creationtime;
			my $pagefaults;
			my $workingset; #physical memory
			my $pagefile; #virgual memory
			my %procmem;

			
		
			$obj->Open($EnumInfo[$i]->{ProcessId},PROCESS_QUERY_INFORMATION | PROCESS_VM_READ,INHERITED,\$Hnd); 
		    $obj->GetStatus($Hnd,\$TimeInfo,DIGITAL);
			#added to close handles
			$obj->CloseHandle($Hnd);
			

			$pid = $EnumInfo[$i]->{ProcessId};
			$procname = $EnumInfo[$i]->{ProcessName};
			my @usertime = split(":",$TimeInfo->{UserTime});
			$usersecs = convert_to_seconds($usertime[0],$usertime[1],$usertime[2],$usertime[3]);
			my  @kerneltime = split(":",$TimeInfo->{KernelTime});
			$kernelsecs = convert_to_seconds($kerneltime[0],$kerneltime[1],$kerneltime[2],$kerneltime[3]);
			$cputime = $usersecs + $kernelsecs;
			if ($debug) {print("Pid = $pid procname = $procname usersecs = $usersecs kernelsecs = $kernelsecs cputime = $cputime\n")}
		
			
			#here we check to see if there is psapi? - call a function to check if there is a dll, return hash
			if ($GetProcessMemoryInfo) {
				print "GETTING process info from GetProcessInfo\n";
				my %Proc;
				%Proc = &GetProcessInfo($pid);
				$pagefaults = $Proc{workingsetpeak};
				$workingset = $Proc{workingset} /1024;
				$pagefile = $Proc{pagefileuse}/ 1024;
			} 
			else 
			{
				#call the GetProcessMeminfo - unfortunately this has a handle leak, but use it where there is no psapi dll
				$obj->GetProcessMemInfo($EnumInfo[$i]->{ProcessId},\$Info);
				$pagefaults = $Info->{PageFaultCount};
				$workingset = $Info->{WorkingSetSize}/1024;
				$pagefile= $Info->{PagefileUsage}/1024;
			}
		
			if ($debug ) {print("pagefaults = $pagefaults workingset =$workingset pagefile= $pagefile\n")}
			
			#replace variables 

			push @running,$pid;  #will return @running                             
			my %running;
					
							
			$running{$pid} = [$pid,$procname,undef,$cputime,$kernelsecs,$usersecs,$workingset,$pagefaults,$pagefile,undef,undef];

			
			if ($debug) {$lh->log_print("Process Id = $pid. User seconds = $usersecs. Kernel Seconds = $kernelsecs. CPU Time = $cputime")}

			if ($taskreset) {
				&vadmin::data1::updatepid($datasession, $debug, $lh,$host,@{$running{$pid}});	
			}	
			

			if (%prevrunning) 
			{  #will be untrue on first run
						if ($pidcompare->compare(\@{$running{$pid}},\@{$prevrunning{$pid}})) {
							if ($debug) {$lh->log_print("MATCHES ARRAY - DO NOT UPDATE $EnumInfo[$i]->{ProcessId}")};	
							$noupdate++;
						} 
						else 
						{ # does not match, insert record   
							if ($debug) {$lh->log_print("NO MATCH ARRAY - UPDATE $pid ")};
							#print "PREVOUS ARRAY = @{$prevrunning{$pid}\n";
							#print "NEW ARRAY = @{$running{$pid}}\n";
							$update++;
							&vadmin::data1::updatepid($datasession, $debug, $lh,$host,@{$running{$pid}});	
						}		 			
			} 
			else 
			 { #no previous hash, insert everything
					if ($debug) {$lh->log_print("NO PREVIOUS ARRAY -UPDATE $EnumInfo[$i]->{ProcessId} ")};
					&vadmin::data1::updatepid($datasession, $debug, $lh,$host,@{$running{$pid}});	
			 }
						

			if (%prevrunning) {delete $prevrunning{$pid}}
					$prevrunning{$pid} = [$pid,$procname,undef,$cputime,$kernelsecs,$usersecs,$workingset,$pagefaults,$pagefile,undef,undef];
					%running = undef;

			print "updates = $update noupdates = $noupdate\n";

		} # end enum processes

		$obj = undef;
		(@EnumInfo,$i,$Info) = undef;
	
	return @running;

}


sub GetProcessInfo()
{
    my( $Pid ) = @_;
    my( %ProcInfo );

    $ProcInfo{name} = "unknown";
    $ProcInfo{pid}  = $Pid;

    my( $hProcess ) = $OpenProcess->Call( $PROCESS_QUERY_INFORMATION | $PROCESS_VM_READ, 0, $Pid );
    if( $hProcess )
    {
        my( $BufferSize ) = $MODULE_LIST_SIZE * $DWORD_SIZE;
        my( $MemStruct ) = MakeBuffer( $BufferSize );
        my( $iReturned ) = MakeBuffer( $BufferSize );      
		
        my $BufSize = 10 * $DWORD_SIZE;
        $MemStruct = pack( "L10", ( $BufSize, split( "", 0 x 9 ) ) );

		
		if( $GetProcessMemoryInfo->Call( $hProcess, $MemStruct, $BufSize ) )
        {
          my( @MemStats ) = unpack( "L10", $MemStruct );
          $ProcInfo{workingsetpeak} = $MemStats[2];
          $ProcInfo{workingset} = $MemStats[3];
          $ProcInfo{pagefileuse} = $MemStats[8];
          $ProcInfo{pagefileusepeak} = $MemStats[9];
			print "######### $ProcInfo{workingset} \n";
		
		}


        $CloseHandle->Call( $hProcess );
    }
    return( %ProcInfo );
}

sub MakeBuffer
{
    my( $BufferSize ) = @_;
    return( "\x00"  x $BufferSize );
}

sub FixString
{
    my( $String ) = @_;
    $String =~ s/(.)\x00/$1/g if( Win32::API::IsUnicode() );
    return( unpack( "A*", $String ) );
}

sub FormatNumber
{
    my( $Number ) = @_;
    while ($Number =~ s/^(-?\d+)(\d{3})/$1,$2/){};
    return( $Number );
}


sub convert_to_seconds {
	my ($hours,$mins,$secs,$milsecs) = @_;

	$milsecs = "." . $milsecs; #gotta love perl...automagically understands what i'm saying here
	print "MILSECS = $milsecs\n";
	$secs += $milsecs;

    $secs += $mins * 60;
	$secs += $hours * 3600;
	return $secs;
}