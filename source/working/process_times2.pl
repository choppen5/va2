
use Win32::API;

while (1) {
	&printprocs;
	sleep(2);
}


sub printprocs {

	$pid = "68524"; #processid - your process id goes here.

	my $OpenProcess = new Win32::API( 'kernel32.dll', 'OpenProcess', [N,I,N], N ) || die "Can not link to open proc";
	my $GetProcessTimes = new Win32::API('kernel32', 'GetProcessTimes',[I,P,P,P,P], 'I');
	my $FileTimeToDosDateTime = new Win32::API('kernel32', 'FileTimeToDosDateTime',[P,P,P], 'I');

	$PROCESS_QUERY_INFORMATION = 0x0400;
	$PROCESS_VM_READ = 0x0010;
	my $lpCreationTime = pack 'I2', 0, 0;   # 100ns since 1/1/1601
	my $lpExitTime = pack 'I2', 0, 0;
	my $lpKernelTime = pack 'I2', 0, 0;
	my $lpUserTime = pack 'I2', 0, 0;

	my( $hProcess ) = $OpenProcess-> Call( $PROCESS_QUERY_INFORMATION | $PROCESS_VM_READ, 0, $pid ) || die "$!";


	my $ret = $GetProcessTimes->  Call($hProcess, $lpCreationTime, $lpExitTime,
	   $lpKernelTime, $lpUserTime);

	 print "\n";
	 printf "lpCreationTime=%u, %u\n", reverse unpack 'I2', $lpCreationTime;
	 printf "lpExitTime=%u, %u\n", reverse unpack 'I2', $lpExitTime;
	 printf "lpKernelTime=%u, %u\n", reverse unpack 'I2', $lpKernelTime;
	 printf "lpUserTime=%u, %u\n\n", reverse unpack 'I2', $lpUserTime;

	@test = reverse unpack 'I2', $lpKernelTime;
	@test2 =  reverse unpack 'I2', $lpUserTime;

	print "@test, @test2";

}