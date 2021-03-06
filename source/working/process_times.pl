
use Win32::API;

$pid = "3926"; #processid - your process id goes here.

my $OpenProcess = new Win32::API( 'kernel32.dll', 'OpenProcess',[N,I,N], N ) || die "Can not link to open proc";

 $GetProcessTimes = new Win32::API('kernel32', 'GetProcessTimes',
    [qw(I P P P P)], 'I') or die 'Failed to get GetProcessTimes: ',
    Win32::FormatMessage (Win32::GetLastError ());

my( $hProcess ) = $OpenProcess->Call( $PROCESS_QUERY_INFORMATION | $PROCESS_VM_READ, 0, $pid );

 my $lpCreationTime = pack 'I2', 0, 0;   # 100ns since 1/1/1601
 my $lpExitTime = pack 'I2', 0, 0;
 my $lpKernelTime = pack 'I2', 0, 0;
 my $lpUserTime = pack 'I2', 0, 0;
 
 my $ret = $GetProcessTimes->Call($hProcess, $lpCreationTime, $lpExitTime,
    $lpKernelTime, $lpUserTime) or die "Call GetProcessTimes: ",
    Win32::FormatMessage (Win32::GetLastError ());

 print "\n";
 printf "lpCreationTime=%u, %u\n", reverse unpack 'I2', $lpCreationTime;
 printf "lpExitTime=%u, %u\n", reverse unpack 'I2', $lpExitTime;
 printf "lpKernelTime=%u, %u\n", reverse unpack 'I2', $lpKernelTime;
 printf "lpUserTime=%u, %u\n\n", reverse unpack 'I2', $lpUserTime;
 
 #return reverse (unpack 'I2', $lpKernelTime), reverse (unpack 'I2', $lpUserTime);

