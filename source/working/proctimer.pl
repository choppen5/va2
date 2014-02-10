 use strict;
 use Win32::API;
 
 our $debug = 0;
 
 our $QueryPerformanceCounter;           # API function object once set in init
 our $QueryPerformanceFrequency;         # API function object once set in init
 our $QPC_Freq;                          # computed freq of QPC in seconds
 our $QPC_Ovhd;                  # computed overhead of QPC API call in seconds
 our $GetProcessTimes;           # get kernel/user times for process
 our $GetCurrentProcess;         # get process handle
 
 # test code
 
 init_QPC ();
> 
> print "\n";
> printf "QPC_Freq: %9.6f usecs (%u per sec)\n", 1000000 / $QPC_Freq, $QPC_Freq;
> printf "QPC_Ovhd: %9.6f usecs\n", $QPC_Ovhd * 1000000;
> 
> # test loop
> 
> init_getCPU ();
> 
> my @start = getCPU ();          # get CPU usage before
> print "\@start = @start\n";
> 
> my $tot_start = start_PC_timer ();
> 
> # stuff to time goes in here **********************************************
> 
> for (1 .. 10) {
> 
>          # start timer
> 
>          my $start = start_PC_timer ();
> 
>          # time the get GTC res routine as a test of timer
> 
>          my $gtc_res = get_GTC_resolution ();
>          printf "GTC res: %.6f msecs\n", $gtc_res;
> 
>          # stop timer
> 
>          my $et = stop_PC_timer ($start);
>          printf "ET     : %.6f secs\n", $et;
> }
> 
> # stuff to time goes in here **********************************************
> 
> my $tot_et = stop_PC_timer ($tot_start);
> 
> my @end = getCPU ();            # get CPU usage after
> print "\@end = @end\n";
> 
> my @usage = compute_usage (\@start, \@end, $tot_et);
> 
> print "\n";
> printf "Kernel : %.6f%%\n", $usage[0];
> printf "User   : %.6f%%\n", $usage[1];
> print "\n";
> 
> exit;
> 
> #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
> 
> # Time GetTickCount resolution - test routine
> 
> sub get_GTC_resolution {
> 
> my $total = 0;
> my $max_loops = 100;
> my $tot_loops = 0;
> for (1 .. $max_loops) {
> 
>          my $loops = 0;
>          my $count1 = Win32::GetTickCount();
>          my $count2 = $count1;
>          while ($count1 == $count2) {
>                  $count2 = Win32::GetTickCount();
>                  $loops++;
>          }
>          $total += $count2 - $count1;
>          $tot_loops += $loops;
> }
> my $res = $total / $max_loops;
> printf "GetTickCount min res: %u ms, ", $res if $debug;
> print "Took ", $tot_loops / $max_loops, " loops on average\n\n" if $debug;
> return $res;
> 
> }
> 
> #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
> 
> sub init_QPC {          # set 4 global vrbls for using timing routines
> 
> $QueryPerformanceCounter = new Win32::API('kernel32',
>    'QueryPerformanceCounter', [qw(P)], 'I') or die
>    'Failed to get QueryPerformanceCounter: ', Win32::FormatMessage (
>    Win32::GetLastError ());                      # set global
> 
> $QueryPerformanceFrequency = new Win32::API('kernel32',
>    'QueryPerformanceFrequency', [qw(P)], 'I') or die
>    'Failed to get QueryPerformanceFrequency: ', Win32::FormatMessage (
>    Win32::GetLastError ());                      # set global
> 
> my $freq = pack 'I2', 0;
> if (not $QueryPerformanceFrequency->Call($freq)) {
>          die 'QueryPerformanceFrequency call failed: ',
>          Win32::FormatMessage (Win32::GetLastError ());
> }
> 
> my @freq = reverse unpack 'I2', $freq;
> $QPC_Freq = $freq[0] * 2**32 + $freq[1];        # set global
> 
> printf "QueryPerformanceCounter freq: 1/%u sec\n\n", $QPC_Freq if $debug;
> 
> $QPC_Ovhd = get_QPC_overhead ();                # set global
> 
> }
> 
> #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
> 
> sub get_QPC_overhead {
> 
> my $ctr1 = pack 'I2', 0;
> my $ctr2 = pack 'I2', 0;
> if (not $QueryPerformanceCounter->Call($ctr1)) {
>          die 'QueryPerformanceCounter call failed: ',
>          Win32::FormatMessage (Win32::GetLastError ());
> }
> 
> my $max_loops = 100;            # adjust down to lower overhead
> my $total = 0;
> for (1 .. $max_loops) {
> 
>          $QueryPerformanceCounter->Call($ctr1);
>          $QueryPerformanceCounter->Call($ctr2);
> 
>          my @ctr1 = reverse unpack 'I2', $ctr1;
>          my @ctr2 = reverse unpack 'I2', $ctr2;
> 
>          printf "Start Value: %u, %u\n", $ctr1[0], $ctr1[1] if $debug;
>          printf "End Value:   %u, %u\n", $ctr2[0], $ctr2[1] if $debug;
> 
>          my $diff = ($ctr2[0] * 2**32 + $ctr2[1]) -
>            ($ctr1[0] * 2**32 + $ctr1[1]);
>          printf "diff: %u / freq: %u = %f\n\n", $diff, $QPC_Freq,
>            $diff / $QPC_Freq if $debug;
>          $total += $diff;
> }
> my $ovhd = $total / $max_loops / $QPC_Freq;
> printf "API Overhead: %.4f usecs\n", $ovhd * 1000000 if $debug;
> return $ovhd
> 
> }
> 
> #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
> 
> sub start_PC_timer {
> 
> init_QPC () if not $QueryPerformanceCounter;
> 
> my $ctr1 = pack 'I2', 0;
> $QueryPerformanceCounter->Call($ctr1);
> my @ctr1 = reverse unpack 'I2', $ctr1;
> return \@ctr1;
> 
> }
> 
> #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
> 
> sub stop_PC_timer {
>          my $ctr1ref = shift;
> 
> my $ctr2 = pack 'I2', 0;
> $QueryPerformanceCounter->Call($ctr2);
> my @ctr2 = reverse unpack 'I2', $ctr2;
> my $diff = ($ctr2[0] * 2**32 + $ctr2[1]) - ($ctr1ref->[0] * 2**32 +
>    $ctr1ref->[1]);
> my $et = ($diff - $QPC_Ovhd) / $QPC_Freq;
> printf "Elapsed time: %f secs\n", $et if $debug;
> return $et;
> 
> }
> 
> #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
> 
> sub init_getCPU {       # init_getCPU ();
> 
> # BOOL GetProcessTimes (HANDLE hProcess, LPFILETIME lpCreationTime,
> #   LPFILETIME lpExitTime, LPFILETIME lpKernelTime, LPFILETIME 
> lpUserTime);
> 
> $GetProcessTimes = new Win32::API('kernel32', 'GetProcessTimes',
>    [qw(I P P P P)], 'I') or die 'Failed to get GetProcessTimes: ',
>    Win32::FormatMessage (Win32::GetLastError ());
> 
> $GetCurrentProcess = Win32::API->new('kernel32', 'GetCurrentProcess',
>    [], 'I') or die "Find GetCurrentProcess: ",
>    Win32::FormatMessage (Win32::GetLastError ());
> 
> }
> 
> #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
> 
> sub getCPU {            # @CPU_times = getCPU ();
> 
> # BOOL GetProcessTimes (HANDLE hProcess, LPFILETIME lpCreationTime,
> #   LPFILETIME lpExitTime, LPFILETIME lpKernelTime, LPFILETIME 
> lpUserTime);
> 
> my $hProcess = $GetCurrentProcess->Call() or # -1 is current process handle
>    die "Call GetCurrentProcess: ", Win32::FormatMessage 
>  (Win32::GetLastError ());
> 
> my $lpCreationTime = pack 'I2', 0, 0;   # 100ns since 1/1/1601
> my $lpExitTime = pack 'I2', 0, 0;
> my $lpKernelTime = pack 'I2', 0, 0;
> my $lpUserTime = pack 'I2', 0, 0;
> 
> my $ret = $GetProcessTimes->Call($hProcess, $lpCreationTime, $lpExitTime,
>    $lpKernelTime, $lpUserTime) or die "Call GetProcessTimes: ",
>    Win32::FormatMessage (Win32::GetLastError ());
> print "\n";
> printf "lpCreationTime=%u, %u\n", reverse unpack 'I2', $lpCreationTime;
> printf "lpExitTime=%u, %u\n", reverse unpack 'I2', $lpExitTime;
> printf "lpKernelTime=%u, %u\n", reverse unpack 'I2', $lpKernelTime;
> printf "lpUserTime=%u, %u\n\n", reverse unpack 'I2', $lpUserTime;
> return reverse (unpack 'I2', $lpKernelTime), reverse (unpack 'I2', 
> $lpUserTime);
> 
> }
> 
> #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
> 
> sub compute_usage {
>          my $startref = shift;
>          my $endref = shift;
>          my $et = shift;
> 
> printf "start=%u, %u, %u, %u\n", $startref->[0], $startref->[1],
>    $startref->[2], $startref->[3];
> printf "end=%u, %u, %u, %u\n", $endref->[0], $endref->[1],
>    $endref->[2], $endref->[3];
> my $kdiff = ($endref->[0] * 2**32 + $endref->[1]) - ($startref->[0] * 2**32 +
>    $startref->[1]);
> my $udiff = ($endref->[2] * 2**32 + $endref->[3]) - ($startref->[2] * 2**32 +
>    $startref->[3]);
> printf "kdiff=$kdiff, udiff=$udiff, et=$et\n";
> return $kdiff / $et / 100000, $udiff / $et / 100000;
> 
> }
> 
> #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
