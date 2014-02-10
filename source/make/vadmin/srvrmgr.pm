package vadmin::srvrmgr;
use FileHandle;
use vadmin::siebparse;

#
# siebel::srvrmgr->new($gateway,$enterprise,$username,$password,$siebelserver,$installpath,$userdefinedsessionid);
# siebel::srvrmgr->startsession();
# siebel::srvrmgr->sendcommand($command);
# siebel::srvrmgr->parse_results();
# siebel::srvrmgr->changestatus($statuscode,$errorcode);
# siebel::srvrmgr->closesession();
#
# Example:
# $newsiebelsess = siebel::srvrmgr->new("gateway", "enterprise", "USERNAME", "PASSWORD", "SIEBELSERVER", "E:\\sea601\\siebsrvr",1);
# 
# $newsiebelsess->sendcommand("list components");
# %hashofarrays = $refe->parse_results;
#  
# $newsiebelsess->closesession(); 
#

sub new { 
	 my $class = shift;
	 my $lh = shift;
	 my $self ={
				GATEWAY => shift,
				ENTERPRISE => shift,
				USERNAME => shift,
				PASSWORD => shift,
				SERVERNAME => shift,
				SERVERPATH => shift,
				SESSID =>     shift,
				REDIRECTFILE => shift,#set this to true to have server manager redirect a file
				LAGTIME => shift || 30, #default is 30, meaning spool commands will wait up for 30 seconds for a file to stop growing
				GROWTHTIME => shift || 1, #growth time is the time (in seconds) waited between checks of file sizes for growth. 
				BINEXE => "\\bin\\srvrmgr.exe",
				VALIDPATH => 0,
				STATUS => 0,
				STARTIME => time(),
				SENTCOMMANDS => 0,
				FILEHANDLE => undef,
				FILEHANDLEREF => undef,
				SPOOLCOMMANDS => 1,
				SPOOLFILE => undef,
				AUTOFLUSH => 1,
				ERROR => undef,
				PID => undef
				};
	
	#set command to a srvrmgr executible
	$self->{COMMAND} = $self->{SERVERPATH}.$self->{BINEXE}." /g " . $self->{GATEWAY} . " /e " . $self->{ENTERPRISE} . " /u ".$self->{USERNAME}." /p " . $self->{PASSWORD} . " /s " . $self->{SERVERNAME};
	$self->{VALIDPATH} = (-f $self->{SERVERPATH}.$self->{BINEXE});
	unless ($self->{VALIDPATH}) {$lh->log_print("ERROR: Server path for $self->{SERVERNAME} : $self->{SERVERPATH} is INVALID.")}; #returns 1 if srvrmgr.exe is found
	$self->{FILEHANDLE} = $self->{SESSID}.$self->{STARTIME};       #creates a filehanle name based on start time and id
	$self->{SPOOLFILE} = $self->{FILEHANDLE}. "spool.txt";#creates a spoolfile name
	$self->{SPOOLFILESTATIC} = $self->{FILEHANDLE}. "spool.txt";#creates a spoolfile name
	
	print "lagtime = $self->{LAGTIME}\n";

    if ($self->{REDIRECTFILE}) {$self->{REDIRECTFILE} = " > ".$self->{FILEHANDLE}.".txt";
    }
     bless($self);
	 return $self;
}


sub startsession {
	my (%retcode,$key);
	#local *FILEH;
	$self = shift;
	$fileh = $self->{FILEHANDLE};
	print "srvmgr command = $self->{COMMAND}\n";
		if ($self->{VALIDPATH}) {
			$self->{PID} = open (FILEH, "| $self->{COMMAND} $self->{REDIRECTFILE}")or print "cannot start session coprocess: $!";
			autoflush FILEH 1;
			$self->{FILEHANDLEREF} = \*FILEH;
			$self->{STATUS} = 1;
			}
	
	return $self;

}


sub sendcommand {
	$self = shift;
	$command = shift;
	#added 4/8/2008 - Charles Oppenheimer
	my $harvesttimeoverride = shift;  # for waiting longer for specific commands
	my $growthtimeoverride = shift;   # for adjusting growthtime for specific commands
	
	my $servertaskcommand = shift; #believe this isn't in use anymore....

	my $rvar = rand(1000);
	my $exitnow;

	#set variables here
	my $growthtime = $growthtimeoverride || $self->{GROWTHTIME};
	my $harvesttime = $harvesttimeoverride || $self->{LAGTIME};

	if ($self->{STATUS} != 0) {	#only send commands if session is running
			unlink ".\\$self->{SPOOLFILE}";
			$self->{SENTCOMMANDS}++;
			my $fileh = $self->{FILEHANDLEREF};
						
			$self->{SPOOLFILE} = $self->{SPOOLFILESTATIC} . $rvar;
			if ($self->{SPOOLCOMMANDS} == 1) {print $fileh "spool ".$self->{SPOOLFILE}."\n"};  #check to see if we spool commands or just send them
			#print "sending command to $fileh\n";
			print $fileh "$command\n";
			if ($self->{SPOOLCOMMANDS} == 1) {print $fileh "spool off\n"};
			
			print "spool file = $self->{SPOOLFILE}\n";		
			my $lagtime = 0;
			my $starttime = time;	
						
			if ($command =~ /exit/) {
				#if its and exit command,don't wait for the file
				$exitnow = 1;
			}

			my $lastsize =  (-s ".\\$self->{SPOOLFILE}") || 0;
			my $growingsize;
			my $currentdiff = 0;
			print "lastsize = $lastsize\n";
			print "system will wait $growthtime seconds between size checks\n";

			do {	
					select(undef,undef,undef,$growthtime);
					my $currentime = time;
					$lagtime = $currentime - $starttime;
					
					$growingsize = -s ".\\$self->{SPOOLFILE}";
					print "Just check size of file = $growingsize, last size =  $lastsize\n";
					$currentdiff = $growingsize - $lastsize;
					print "currentdiff = $currentdiff, growingsize = $growingsize, lastsize = $lastsize \n";
					$lastsize = $growingsize;


					print "waiting for file creation lag =$lagtime, startime = $starttime and currentime = $currentime\n";
					if (($lagtime) > $harvesttime ) { #this can be set in .vconfig, default waitng time is only 5 seconds
						print "******************srvrmgr ERORR!!!!!!!!!!!!!*****Could not find spool file in time!!!********";
						chomp($command); #remove return chars for printing errors
						$self->{ERROR} = "srvrmgr ERORR = HARVEST TIMEOUT. Time $lagtime exceeded havest limit $harvesttime, interval = $growthtime, for command = $command";
						$exitnow = 1;
						#return an error and kill the srvrmgr session?
					}			
			} 
			   #$currentdif will == 0 if the log files have not growin in 1 second, 
			   #the $growingsize check is there because $currentdiff could be 0 before the spoolfile is produced on a system with a long delay (ie a lot of tasks)
			   until (($currentdiff == 0 and ($growingsize > 3 && $lastsize > 3)) || $exitnow ) ;  #for some reason file is spooled to size 3 then hangs...
			   print "FINISHED WAITING FOR FILE currentime = $currentime.  currentdif =  $currentdiff, growingsize = $growingsize, lastsize = $lastsize \n";
			   sleep(1);
			   my $lastsize = $growingsize = -s ".\\$self->{SPOOLFILE}";
			   print "LAST SIZE OF FILE IS: $lastsize \n";
			   
	
		}#end status check

		sleep(1);
	return $self;
}

sub parse_results {
	$self = shift;
	my %hoa;
	my $nofileerror;
	my $servertask= shift;
	open (SF,".\\$self->{SPOOLFILE}") or $nofileerror = 1 ; 
	if ($hoa->{ERROR}) {
		$hoa->{ERROR}="19";
		return %hoa;
	}


	 %hoa = parse_command_result(*SF,$servertask);
	close SF;
	unlink ".\\$self->{SPOOLFILE}";
	return %hoa;
}

sub changestatus {
	$self = shift;
	my $statuscode = shift;
	my $errorcode = shift;
	if ($statuscode > 0) {
		$self->{STATUS} = 0;
		$self->{ERROR} = $errorcode;
	}
	print "status = $self->{STATUS}\n"; 
	return $self;
}

sub closesession {
	$self = shift;
	my $fileh = $self->{FILEHANDLEREF};
	print $fileh "exit\n";
	unlink ".\\$self->{SPOOLFILE}";
	#close $fileh;
	return $self;
}

1;