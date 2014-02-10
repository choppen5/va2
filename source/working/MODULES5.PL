
use Win32::API;
use Getopt::Long;

# Define some contants
$DWORD_SIZE = 4;
$PROC_ARRAY_SIZE = 100;
$MODULE_LIST_SIZE = 200;

# Define some Win32 API constants
$PROCESS_QUERY_INFORMATION = 0x0400;
$PROCESS_VM_READ = 0x0010;


$OpenProcess = new Win32::API( 'kernel32.dll', 'OpenProcess', [N,I,N], N ) || die "Can not link to open proc";
$CloseHandle = new Win32::API( 'kernel32.dll', 'CloseHandle', [N], I ) || die "Can not link to CloseHandle()";
$EnumProcesses = new Win32::API( 'psapi.dll', 'EnumProcesses', [P,N,P], I ) || die;
$EnumProcessModules = new Win32::API( 'psapi.dll', 'EnumProcessModules', [N,P,N,P], I ) || die "Can not link EnumProcessModules";
$GetModuleBaseName = new Win32::API( 'psapi.dll', 'GetModuleBaseName', [N,N,P,N], N ) || die "Can not link to GetModuleBaseName\n";
$GetModuleFileNameEx = new Win32::API( 'psapi.dll', 'GetModuleFileNameEx', [N,N,P,N], N ) || die "Could not link to GetModuleFileNameEx\n";
$GetProcessMemoryInfo = new Win32::API( 'psapi.dll', 'GetProcessMemoryInfo', [N,P,N], I ) || die "Can not link GetProcessMemoryInfo()\n";


while (1) {
	$count++;
	&printprocs;

	print "Cycle =  $count #####\n"; 
	sleep(2);
}	

sub printprocs()
{ 

	if( 0 == scalar @PidList ) 
	{
		@PidList = GetPidList();
	}

	my $iTotal = 0;

		# Create a buffer
		$ProcArray = MakeBuffer( $DWORD_SIZE * $PROC_ARRAY_SIZE );
		$ProcNum = MakeBuffer( $DWORD_SIZE );

		foreach $Pid ( @PidList )
		{
			my $iModuleCount = 0;
			my $ProcInfo = GetProcessInfo( $Pid, \@ModuleList );


			print "\n$ProcInfo->{pid} ($ProcInfo->{name})\n";
		
			printf( "  Current memory use: %s\n  Peak memory use: %s\n",
						FormatNumber( $ProcInfo->{workingset} ),
						FormatNumber( $ProcInfo->{workingsetpeak} ) );
		}
}

sub GetPidList()
{
    my( @PidList );
    my $ProcArrayLength = $PROC_ARRAY_SIZE;
    my $iIterationCount = 0;
    my $ProcNum;
    my $pProcArray;

    do
    {
        my $ProcArrayByteSize;
        my $pProcNum = MakeBuffer( $DWORD_SIZE );
        # Reset the number of processes since we later use it to test
        # if we worked or not
        $ProcNum = 0;
        $ProcArrayLength = $PROC_ARRAY_SIZE * ++$iIterationCount;
        $ProcArrayByteSize = $ProcArrayLength * $DWORD_SIZE;
        # Create a buffer
        $pProcArray = MakeBuffer( $ProcArrayByteSize );
        if( 0 != $EnumProcesses->Call( $pProcArray, $ProcArrayByteSize, $pProcNum ) )
        {
            # Get the number of bytes used in the array
            # Check this out -- divide by the number of bytes in a DWORD
            # and we have the number of processes returned!
            $ProcNum = unpack( "L", $pProcNum ) / $DWORD_SIZE;
            print "Total procs: $ProcNum\n";
        }
    } while( $ProcNum >= $ProcArrayLength );
    
    if( 0 != $ProcNum )
    {
        # Let's play with each PID
        # First we must unpack each PID from the returned array
        @PidList = unpack( "L$ProcNum", $pProcArray );
    }
    return( @PidList );
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
		
        $BufSize = 10 * $DWORD_SIZE;
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
    return( \%ProcInfo );
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




