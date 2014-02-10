use Win32::API;
use Getopt::Long;

$VERSION = 20030524;

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
	@PidList = GetPidList();

foreach my $Pid ( @PidList ) {
		print "pid = $Pid\n";
}
sleep(1);
}


sub GetPidList()
{
	print "executing GetPidList\n";
    my( @PidList );
    my $ProcArrayLength = $PROC_ARRAY_SIZE;
    my $iIterationCount = 0;
    my $ProcNum;
    my $pProcArray;

    do
    {
        my $ProcArrayByteSize;
        my $pProcNum = MakeBuffer( $DWORD_SIZE );
        print "Reset the number of processes since we later use it to test\n";
        # if we worked or not
        $ProcNum = 0;
        $ProcArrayLength = $PROC_ARRAY_SIZE * ++$iIterationCount;
        $ProcArrayByteSize = $ProcArrayLength * $DWORD_SIZE;
        # Create a buffer
        $pProcArray = MakeBuffer( $ProcArrayByteSize );
		print "about to call enumprocesses\n";
        if( 0 != $EnumProcesses->Call( $pProcArray, $ProcArrayByteSize, $pProcNum ) )
        {
            # Get the number of bytes used in the array
            # Check this out -- divide by the number of bytes in a DWORD
            # and we have the number of processes returned!
            $ProcNum = unpack( "L", $pProcNum ) / $DWORD_SIZE;
            print "Total procs: $ProcNum\n";
        }
    } while( $ProcNum >= $ProcArrayLength );
    print "returning pid list\n";

    if( 0 != $ProcNum )
    {
        # Let's play with each PID
        # First we must unpack each PID from the returned array
        @PidList = unpack( "L$ProcNum", $pProcArray );
    }
	
    return( @PidList );
}

sub MakeBuffer
{
    my( $BufferSize ) = @_;
    return( "\x00"  x $BufferSize );
}