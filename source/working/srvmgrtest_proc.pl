use vadmin::srvrmgr;
use Log::Logger;
use Win32::IProcess qw(
PROCESS_QUERY_INFORMATION PROCESS_VM_READ INHERITED INHERITED DIGITAL NOPATH
); 

my $lh = new Log::Logger "siebparse.log" ;				# global log file


$refe = vadmin::srvrmgr->new($lh,"localhost","siebel" , "SADMIN", "SADMIN", "IBMT42", "C:\\sea77\\siebsrvr\\",1,undef,10,1);
$refe->startsession;
$svrmgrpid = $refe->{PID};	
$lh->log_print("Started Siebel Srvrmgr session with PID: $svrmgrpid");

			
while (1) {
	$count++;
	&printprocesses;
	my $servereturn = srvrcmd("list tasks for server IBMT42\n");
	print "server return = $servereturn \n";
	print "Cycle =  $count #####\n"; 
	sleep(2);
	

}					

$refe->closesession;
$lh->log_print("Closing Siebel Srvrmgr session with PID: $svrmgrpid");

sub srvrcmd {
	my %qhoa;
	my $cmd = shift;
	my $harvestime = shift;
	my $growthwait = shift;
	
	#	$refe->{ERROR} = undef; #reset any errors

	#1. start a sesson
# if a non session start
	

	if ($refe->{STATUS} > 0) {

		# now send the command in there
		$refe->sendcommand($cmd,$harvestime,$growthwait);
	
				# check for errors sending command
				if ($refe->{ERROR}) {
					#my $datestring = &getdatestring();
					$lh->log_print("ERROR srvrcmd: $refe->{ERROR}");
					#args = my ($sft_elmnt_id,$server,$event_string,$usr_event_level,$usr_event_type,$usr_event_sub_type,$event_time,$error_defs_id,$cc_alias,$host,$analysis_rule_id) =@_;	
					# decide what type of error this is.. is there only one type?
					# if we had an error sendin a command, what do we do? should return here I guess

					#&senderrortovcs($server_id,$siebsrvr,$refe->{ERROR},0,"VLSM_SIEBELCOMMAND","TIMEOUT",$datestring,undef,undef,$host,undef);
					
				}

				if ($cmd=~/list tasks for server/) {
					#it is a server task command, pass in parameter
					%qhoa = $refe->parse_results(1);
				} else {
					%qhoa = $refe->parse_results;	
				}
	  } # refe status is 0 
	  else {
			return 0;	
			# returned with an error
	  }


	 #session status is > 0 - decide if the retuned values 

	 if ($qhoa{ERROR} < 30 && $qhoa{ERROR} > 0) {
		   $refe->changestatus($qhoa{ERROR},$qhoa{ERROR});
		   $lh->log_print("ERROR: $qhoa{ERROR}\nERRORSTRING: $qhoa{ERRORSTRING}");
		   
		   #decide what to do?
		   
	   }


	return %qhoa;
}


sub printprocesses {

	my (@EnumInfo,$i,$Info);	
	my($obj)=new Win32::IProcess || die "Can not create an IProcess object..\n";
	$obj->EnumProcesses(\@EnumInfo);
	#printf("\n\n%11.10s %7.6s %10.9s %15.14s %18.17s %14.13s\n\n",
	#"PageFaults","PeakWS","WS","QuotaPagedPool","QuotaNonPagedPool","PagefileUsage");

	for($i=0;$i<scalar(@EnumInfo);$i++)
		{
			
			my $Hnd;
			my $TimeInfo;

		#printf("%15.14s%19.18s%19.18s%15.14s%7.6s\n\n","[Name]","[UserTime]",
		#      "[KernTime]","[StartTime]","[Pid]");

			$obj->Open($EnumInfo[$i]->{ProcessId},PROCESS_QUERY_INFORMATION | 
              PROCESS_VM_READ,INHERITED,\$Hnd); 
		  $obj->GetStatus($Hnd,\$TimeInfo,DIGITAL);
	
	
			$obj->GetProcessMemInfo($EnumInfo[$i]->{ProcessId},\$Info);
			if ($debug ) {
				printf("%11.10s %7.6s %10.9s %15.14s %18.17s %14.13s\n\n",
				$Info->{PageFaultCount},$Info->{PeakWorkingSetSize},
				$Info->{WorkingSetSize}/ 1024,$Info->{QuotaPagedPoolUsage},
				$Info->{QuotaNonPagedPoolUsage},$Info->{PagefileUsage}/1024);
			}

			push @running,$EnumInfo[$i]->{ProcessId};
			my %running;
			my $cputime; #need this later
			my $usersecs;
			my $kernelsecs;

				foreach (@pids) {
						if ($EnumInfo[$i]->{ProcessId} == $_) {

							my @usertime = split(":",$TimeInfo->{UserTime});
							   $usersecs = convert_to_seconds($usertime[0],$usertime[1],$usertime[2],$usertime[3]);
							 my  @kerneltime = split(":",$TimeInfo->{KernelTime});
							   $kernelsecs = convert_to_seconds($kerneltime[0],$kerneltime[1],$kerneltime[2],$kerneltime[3]);
							  $cputime = $usersecs + $kernelsecs;
											
								print "CPU TIME = $cputime";
								$running{$EnumInfo[$i]->{ProcessId}} = [$EnumInfo[$i]->{ProcessId},$EnumInfo[$i]->{ProcessName},undef,$cputime,$kernelsecs,$usersecs,$Info->{WorkingSetSize}/ 1024,$Info->{PageFaultCount},$Info->{PagefileUsage}/1024,undef,undef];
		
								
								
							  $obj->CloseHandle($Hnd);	
						}
			
				}
		} #END FOR

	$obj = undef;
	(@EnumInfo,$i,$Info) = undef;

}