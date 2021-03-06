use vadmin::srvrmgr;
use Log::Logger;

my $lh = new Log::Logger "siebparse.log" ;				# global log file


$refe = vadmin::srvrmgr->new($lh,"localhost","siebel" , "SADMIN", "SADMIN", "IBMT42", "C:\\sea77\\siebsrvr\\",1,undef,10,1);
$refe->startsession;
$svrmgrpid = $refe->{PID};	
$lh->log_print("Started Siebel Srvrmgr session with PID: $svrmgrpid");

			
while (1) {
	$count++;
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