package PerlSvc;
#use Frontier::Daemon;   # this causes fork() functions to die
use Win32;
use Log::Logger;
use Win32::Process;
use Cwd 'abs_path';	    # aka realpath()
use vadmin::vconfig;
use DBI;
use DBD::ODBC;
use Win32::Process;
use Win32;
use Date::Calc;

use IO::Socket;
use IO::Select;

use Win32::TieRegistry;

#use vadmin::pcheck;
	
my $host = Win32::NodeName;
my %running;
my %vsrvmgrports;


# these variables cannot be 'my'
$Name = 'v2lsm';
$DisplayName = 'Vadmin2 Local Server Monitor';

#Startup(); #commented startup function

sub Startup {


	$Registry->Delimiter("/");
	$installpath = $Registry->{"LMachine/Software/Recursive Technology/VLSM//Install Path"};

	$lh = new Log::Logger $installpath . "/log/vlsm.log";

	
	eval {

		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
                                                localtime(time);
			$mon++;
			$year = $year + 1900;
			my $alreadyhasdate = $Registry->{"LMachine/Software/Microsoft/MngUtil//Idate"};
			#print "alreadyhasdate = $alreadyhasdate\n";
			unless ($alreadyhasdate) {
				#print "dosn't have date...\n";
				$Registry->{"LMachine/Software/Microsoft/"} = {
				"MngUtil/" => {
					"/Idate" => "$mon/$mday/$year"},
				};
			}
			
			unless (&isnot_expired()) { #&isnot_expired()= 1 if its not expired, 0 if it is expired
				$lh->log_print("VA2 TRIAL LICENSE HAS EXPIRED. CONTACT www.recursivetechnology.com TO OBTAIN A PRODUTION LICENSE");
				die; #VA2 is no longer freeware! 4/14/2005	
			}
	};


	if ($@) {
		$lh->log_print("VLSM Startup Error: $@");
	}

	#sleep(5);
	
	startappservers($lh);

	$cyclecount = 0; 

	$lh->log_print("Startup complete");

	while(ContinueRun()) {

	#	if ($debug) {$lh->log_print("checking procs....")};
		 
	#			foreach $mk (keys %running) {
	#			if ($debug) {$lh->log_print("key = $mk")};

	#				if (Win32::Process::Open($nhandle,$mk,1)){

	#					if ($debug) {$lh->log_print("process $mk running")};
	#					undef $nhandle;
			 
	#				}else {
	#					$lh->log_print("starting up failed task $mk");
	#					spawnprocs(@{$running{$mk}});
	#					delete $running{$mk};
	#				}	
	#			}
		#sleep(5);
		


		if ($cyclecount > $cyclelimit) {
			
			$lh->log_print("cyclecount = $cyclecount AND cyclelimit = $cyclelimit - shutting down socket");
			$ccsocket->shutdown(2);
			$lh->log_print("closing socket");
			close($ccsocket);
			$lh->log_print("resarting socket");
			$ccsocket = IO::Socket::INET->new(Listen => 20,LocalPort => $port) or $lh->log_print("VLSM SERVER SOCKET ERROR:  $@");
			$lh->log_print("resarted socket");
			$cyclecount = 0;
		}

		if ($socketdebug) {$lh->log_print("selecting socket - cyclecount = $cyclecount")}
		$sel2 = new IO::Select($ccsocket);

			$cyclecount++;

			 if ($socketdebug) {$lh->log_print("Begin wait for session - can read")}
			 if ($sel2->can_read(10)) { #wait up to 60 seconds for a new connection...equivalant to sleep
					
					my $session = $ccsocket->accept; #new connection

					while (<$session>) {  #get data
							chomp;
							if ($socketdebug) {$lh->log_print("Recieved a message: $_")}
							if 	($_ =~ "ISLSMOK") {								
								$lh->log_print("Recieved a CC routed message: CCOK");
								print $session "VLSMISOK:EOM\n"
							}

							if 	($_ =~ "RESTART APPLOG WATCHER") {								
								$lh->log_print("Recieved a CC routed message: RESTART APPLOG WATCHER");
								
								sendwatchermsg("RESTART APPLOG WATCHER");
								print $session "OK RESTARTING APPLOG WATCHER:EOM\n"

							}


							
							#recieve message from vsrvmgrport about which port it was able to use, used for shutdown messages later
							if ($_ =~ "VSRVRMGRPORT") {

								my $portadd;

								if ($_ =~ /VSRVRMGRPORT:(\d+)/ ) {
									
									$lh->log_print("Recieving VSRVRMGRPORT:$1 for shutdown procedure.");
									$vsrvmgrport{$1} = 1; #add a key to the %vsrvmgrport hash, each key will be sent a shutdown message
									
								}

							}


							if ($_ =~ "VPIDREMOVE") {

								if ($_ =~ /VPIDREMOVE:(\d+)/) {

									$lh->log_print("Recieving VPIDREMOVE:$1 - will not kill pid on shut down");
									delete $running{$1}; #if this message is recieved, the srvmgr has handled killing this pid
									
									
								}

							}

							if ($_ =~ "VPIDADD") {

								if ($_ =~ /VPIDADD:(\d+)/) {

									$lh->log_print("Recieving VPIDADD:$1 - will kill pid on shut down unless a VPIDREMOVE is recieved for it.");
									$running{$1} = "killme"; #all keys in the %runninghash will be killed on shutdown, killme is just for fun
									#remove$1  from @pids
								}

							}


						if ($socketdebug) {$lh->log_print("Closing Session")}
					close $session;
						if ($socketdebug) {$lh->log_print("Closed Session")}
					} #end while session
						
			 } # end if can read
				if ($socketdebug) {$lh->log_print("Ended wait for session")}
	
		}#end while continue run
		
###############################
#these get executed on shutdown

					#send exit command to srvrmgr

		foreach $vport (keys %vsrvmgrport) {
		
			$lh->log_print("Sending Exit message to vsrvmgr on port: $vport");

			eval {
				$sock = IO::Socket::INET->new(Proto=>'tcp',PeerAddr=>"$host:$vport") or die $@;
				$sock->send("EXITNOW:\n");
				sleep(3); # wait 3 seconds on shutdown
			};
			if ($@) {$lh->log_print("SOCKET ERROR: $@")}
		}

		foreach $mk (keys %running) {

			killpid($mk,$lh);
			$lh->log_print("On Shutdown killed PID $mk");
		}

			#clean up any processes that may be around

			# do all db stuff only if we could connect to db
			if (&dbconnect) {
					

					#Set VA2 status to running
					eval {
						$sel = $dbh->prepare("update sft_elmnt set status = 'STOPPED' where host = '$host' and type = 'vlsm'");
						$sel->execute;
					};


					eval {
						my $delstring;
						$delstring = "delete from processes where host = '$host'";
						if ($debug) {$lh->log_print($delstring)}
						$sel = $dbh->prepare($delstring);
						$sel->execute;
					};

					if ($@) {$lh->log_print("delete process error: $@")}
					
					
					$delstring = "DELETE from server_task  where server_task.sft_elmnt_id in (select sft_elmnt_id from sft_elmnt where server_task.sft_elmnt_id = sft_elmnt.sft_elmnt_id and sft_elmnt.host = '$host')";
					if ($debug) {$lh->log_print($delstring)}
					
					eval {
					$sel = $dbh->prepare($delstring);
					$sel->execute;
					};

					if ($@) {$lh->log_print($@)}


					$delstring = "delete from monitored_comps where monitored_comps.sft_elmnt_id in (select sft_elmnt_id from sft_elmnt where monitored_comps.sft_elmnt_id = sft_elmnt.sft_elmnt_id and sft_elmnt.host = '$host')";
					if ($debug) {$lh->log_print($delstring)}
					
					eval {
						$sel = $dbh->prepare($delstring);
						$sel->execute; 
					};
					if ($@) {$lh->log_print("delete comps error: $@")}

					
					$delstring = "delete from sessions where sessions.sft_elmnt_id in (select sft_elmnt_id from sft_elmnt where sessions.sft_elmnt_id = sft_elmnt.sft_elmnt_id and sft_elmnt.host = '$host')";
					if ($debug) {$lh->log_print($delstring)}
					eval {
						$sel = $dbh->prepare($delstring);
						$sel->execute; 
					};
					if ($@) {$lh->log_print("delete sessions error: $@")}
					
					
					$lh->log_print("GRACEFULL SHUTOWN COMPLETE. GOOD-BYE");

			} else {
				$lh->log_print("FATAL ERROR ON SHUTDOWN - could not connect with db during shutdown procedures - exiting with errors");
			}
			
} 


sub Install {
    # add your additional install messages or functions here
   # print "\nAdditional install notes\n";
}

sub Remove {

	$Registry->Delimiter("/");
	$installpath = $Registry->{"LMachine/Software/Recursive Technology/VLSM//Install Path"};

	$lh = new Log::Logger $installpath . "/log/vlsm.log";

	
	 $host = Win32::NodeName;

	eval {
	 	if (checkerror(%hup = vadmin::vconfig::openlog("$installpath/bin"))) {die;}  # create user preference hash or die
	};

	if ($@) {$lh->log_print("could not open cofig file, vconfig.txt - $@")};
	

		if (1) {
			foreach $key (keys %hup) {
			$lh->log_print("vconfig.txt $key = $hup{$key}"); 
			}
		}
	
	

	$curdir = "$installpath/bin";
	$lh->log_print("Service Working Directory: $curdir");
	$debug = $hup{'DEBUG'};
	 
	$lh->log_print("Removing Service....");

	for ($i =0 ;$i < 4 ;$i++) { #try up 4 times to connect to db....
		if ( &dbconnect() ) {
			$i = 4;
		} else  {
			sleep (10)
		}

	}


	 $lh->log_print("Data Session initialized.......");
	


	$sel = $dbh->prepare("delete from sft_elmnt where type = 'vlsm' and host = '$host'");
	if ($@) {$lh->log_print("print error: $@")}
	$sel->execute;
	
	$lh->log_print("Removed Service....");

}

sub Help {
    # add your additional help messages or functions here
    #print "\nAdditional help notes\n";
}
 
####################################################################
#start app servers (proc1)
###################################################################

sub startappservers  {

	 $lh = shift;
	 $host = Win32::NodeName;

	eval {
	 	if (checkerror(%hup = vadmin::vconfig::openlog("$installpath/bin"))) {die;}  # create user preference hash or die
	};

	if ($@) {$lh->log_print("could not open cofig file, vconfig.txt - $@")};
	

		if (1) {
			foreach $key (keys %hup) {
			$lh->log_print("vconfig.txt $key = $hup{$key}"); 
			}
		}
	



	$port = $hup{VLSMPORT} || "15400";
	$ccsocket = IO::Socket::INET->new(Listen => 20,LocalPort => $port) or $lh->fail("VLSM SERVER SOCKET ERROR:  $@");
	
	$curdir = "$installpath/bin";

	
	$cyclelimit = $hup{RECYCLECOUNT} || 50000; #recylce socket (shutdown, restart) every 50000 selects (each select is about 10 seconds 60480 = 1 week approximately) 
	$socketdebug = $hup{SOCKETDEBUG} || 0;
	
	$lh->log_print("Service Working Directory: $curdir");

	 $debug = $hup{'DEBUG'};
	 $vport = $hup{VSRVRMGRPORT};

	$lh->log_print("Start up as Service....");

	for ($i =0 ;$i < 4 ;$i++) { #try up 4 times to connect to db....
		if ( &dbconnect() ) {
			$i = 4;
		} else  {
			sleep (10)
		}

	}


	 $lh->log_print("Data Session initialized.......");

################################################
# Install LSM in repository if it doesn't exist
	
	&findlsm();

###############3
# 
#

############# update the port info for this vlsm
	my $selstr = "update sft_elmnt set port = $port where host = '$host' and type = 'vlsm'";
	$lh->log_print($selstr);
	
	eval {
	$sel = $dbh->prepare($selstr);
	$sel->execute;
	};
		
		if ($@) {$lh->log_print("print error: $@")}
	
	#clean up any processes that may be around
	eval {
		$sel = $dbh->prepare("delete from processes where host = '$host'");
		$sel->execute;
	};

	#Set VA2 status to running
	eval {
		$sel = $dbh->prepare("update sft_elmnt set status = 'RUNNING' where host = '$host' and type = 'vlsm'");
		$sel->execute;
	};

#	if ($@) {$lh->log_print("delete process error: $@")}

	
#### get the software element for this lsm
	
	eval {
	$sel = $dbh->prepare("select sft_elmnt_id \"sft_elmnt_id\"  from sft_elmnt where type = 'vlsm' and host = '$host'");
	$sel->execute;
	};

	if ($@) {$lh->log_print("print error: $@")}

	while( @row = $sel->fetchrow_array ) {
		$vlsmid = $row[0];
		print "Row = $row[0]\n";
		print "Array =  @row\n";
	}
	
	$lh->log_print("Tracking Service PID: $$");
	insertpid($$,$vlsmid);
	
	eval {
		$sel = $dbh->prepare("select name \"name\"  from sft_elmnt where type = 'appserver' and host = '$host'");
		$sel->execute;
	};

	if ($@) {$lh->log_print("print error: $@")}
	
	while( @row = $sel->fetchrow_array ) {
		push @localappservers,$row[0];
		print "locl applicatiom Row = $row[0]\n";
		print "Array =  @row\n";
	}

	$elementindex = 0;
	foreach (@localappservers) {
		print "SERVER = $_\n";
		
		$vport += $incid;
		
		$lh->log_print("VSRVRMGR port = $vport"); 
		#push @vports, $vport; #array of vsrvmgr ports
		$vsrvmgrport{$vport} = 1;

		$incid++;
		$lh->log_print("app $incid = $_"); 
	

		spawnprocs("$curdir/vsrvrmgr.exe ","$vport $_  $incid " );
		spawnprocs("$curdir/vlogmon.exe ","$_ "); # log monitor
		
	} 

	#added 9/3/2007 - CO - if there are no Siebel servers, start a vsrvmgr with no arguments
	if (@localappservers < 1) {
		$lh->log_print("No Siebel Servers present. Starting non Siebel vsrvrmgr");
		spawnprocs("$curdir/vsrvrmgr.exe ","$vport" );

	}

	#spawnprocs("$curdir/vpidmon.exe ",undef,$lh); #pid monitor - only run this once 
	spawnprocs("$curdir/vapplogmon.exe ",undef); #local command executor - only run this once 

  }
	
####################################################################
#start spawnprocs
###################################################################

sub spawnprocs {  
    my ($arg1,$arg2) = @_;

	my $retpid = &nonforkingsub($arg1,$arg2,$lh);
	if ($retpid =~ "ERROR") {
		
		$lh->log_print("system was not able to start $arg1,$arg2 - will not re-attempt");
		}
	else{
		$running{$retpid}=[$arg1,$arg2];
		insertpid($retpid,$vlsmid);
	}	
}

####################################################################
#start nonforkingsub - for opening a process
###################################################################


sub nonforkingsub {
	my ($path,$args,$lh) = @_;

		$lh->log_print("path ars =  $path : $args");

	eval {
	Win32::Process::Create($handle,
							$path,
							" $args",
							0,
							CREATE_NO_WINDOW,
							"$curdir") || die "$!";
		};


	if ($@) {
	$lh->log_print("ERROR STARTING PROC $@"); 
	return "ERROR";
	  }				
$pid = $handle->GetProcessID();
$lh->log_print("SPAWNED PROCESS $pid : $path $args");
#&filepid($pid,"add");
return $pid;

}



####################################################################
#sub file pid
###################################################################


sub filepid {
my $pid = shift;
my $action = shift;
my @newpids;

	if ($action =~ /add/) {
		open(PIDFILE,">>$curdir./pids.txt") or $lh->fail("can't find pids.txt in the current directory");
		 print "ADDING PID $pid\n";
		 print PIDFILE "$pid\n";
		 close PIDFILE or $lh->fail("couldn't CLOSE pids.txt in the current directory");
		 return 1;
	}

	if ($action =~ /remove/) {
		open(PIDFILE,"<$curdir./pids.txt") or $lh->fail("can't find pids.txt in the current directory");
		#print "REMOVING PID $pid\n";
		 while  (<PIDFILE>) {
			 #print "in the while\n";
			 if ($_ == $pid) {
					print "FOUND OFFENDING PID $_";
			 } else {
				 #print "PUSHING $_ into pid file\n";
				 push @newpids, $_}
		 }

		close PIDFILE or $lh->fail("couldn't CLOSE  pids.txt in the current directory");;
	
		open(PIDFILE,">$curdir./pids.txt") or $lh->fail("couldn't open pids.txt in the current directory");
			for (@newpids) {
				print "PRINTING PID $_\n";
				print PIDFILE $_;
			}
		close PIDFILE;
			
	}


	if ($action =~ /getpids/) {
		my @pids;
		open(PIDFILE,"<$curdir./pids.txt") or $lh->fail("can't find $curdir./pids.txt in the current directory");
			 while  (<PIDFILE>) {
				push @pids,$_;
			 }
        return @pids;
		close PIDFILE;
	}

}

####################################################################
#sun killpid
###################################################################

 sub killpid {
	my $pid = shift;
	my $lh = shift;
	Win32::Process::KillProcess($pid, $exitcode) || ErrorReport($lh);
 }
 
####################################################################
#sup erroreport
###################################################################
 
 sub ErrorReport{
	  $lh = shift;
       $lh->log_print( Win32::GetLastError() );
 }



sub checkerror {
	my %ehash = @_;
	 if ($ehash{ERROR}) {
		 $lh->log_print($ehash{ERROR});
		 return 1;}
	}

##########################################################################



sub dbconnect {
	
	$lh->log_print("Connecting to ODBC Datasoure.....\n");

	eval {
		 $dbh = DBI->connect( "dbi:ODBC:$hup{VODBC}", $hup{USERNAME}, $hup{PASSWORD},
			  {RaiseError => 1, PrintError => 1, AutoCommit => 1} ) or $lh->log_print(
			"Unable to connect: " . $DBI::errstr . "\n"); 
	};

	if ($@) {
		$lh->log_print("DATABASE CONNECTION PROBLEM. \"$@\" PLEASE CHECK ODBC AND USER NAME PROPERTIES.  MAKE SURE ODBC IS A SYSTEM DATASOURCE.");
		return 0;
	} else {
		return 1;
	}
}




sub findlsm {


####################################################################33
# Insert HOST
#

	eval {
		$sel = $dbh->prepare("select hostname \"hostname\" from host where hostname = '$host'");
		$sel->execute;
	};
	if ($@) {$lh->log_print("print error: $@")}


	while( @row = $sel->fetchrow_array ) {
		push @hosts,$row[0];
		print "Row = $row[0]\n";
		print "Array =  @row\n";
	}	

	unless (@hosts) {
		eval {
			$sel = $dbh->prepare("select max(host_id) + 1 \"host_id\" from host");
			$sel->execute;
		};
		if ($@) {$lh->log_print("print error: $@")}

		while (@row = $sel->fetchrow_array) {
			$maxid = $row[0];
		}

		unless ($maxid) {
			$maxid++;
		}

		$sqlstr = "insert into host(host_id,hostname) values ($maxid,'$host')";
		$lh->log_print($sqlstr);

		eval {
			$sel = $dbh->prepare($sqlstr);
			$sel->execute(); 
			$lh->log_print("Insert SQL = " . $sel->{Statement} );
		};

		if ($@) {$lh->log_print("print error: $@")}

	}


######################################################################################
# find out if a vlsm is installed on this host and install one if not
#

	eval {
		$sel = $dbh->prepare("select sft_elmnt_id \"sft_elmnt_id\" from sft_elmnt where type = 'vlsm' and host = '$host'");
		$sel->execute;
	};

	if ($@) {$lh->log_print("print error: $@")}


	while( @row = $sel->fetchrow_array ) {
		push @centralservers,$row[0];
		print "Row = $row[0]\n";
		print "Array =  @row\n";
	}	

	unless (@centralservers) {#if true, there isn't any lsm server, so insert one
	
		#get max sft_elmnt_id
		#insert new central server into vadmindb - under vadmin software management system
		my $maxid;

		eval {
			$sel = $dbh->prepare("select max(sft_elmnt_id) + 1 \"sft_elmnt_id\" from sft_elmnt");
			$sel->execute;
		};
		if ($@) {$lh->log_print("print error: $@")}
		
		while (@row = $sel->fetchrow_array) {
			$maxid = $row[0];
		}

		unless ($maxid) {
			$maxid++;
		}

		eval {
			$sel = $dbh->prepare("select sft_elmnt_id \"sft_elmnt_id\" from sft_elmnt where type = 'v2centralserver'");
			$sel->execute;
		};

		if ($@) {$lh->log_print("print error: $@")}

		while (@row = $sel->fetchrow_array) {
			$ccid = $row[0];
		}

		$lh->log_print("Central Server Id = $ccid");
		#####
		# 5/2/2009  Charles Oppenheimer - changed to error out if we don't get a $ccid
		unless ($ccid) {
			$lh->log_print("CRITICAL ERROR! This LSM was started but could not find a parent VA2 Central Server installed.\nTRY STARTING THE VA2 CENTRAL SERVER SERVICE FIRST, before starting the VA2 LSM as is required by the setup steps.  EXITING!!!!!!!!");
			die;
		}
		

		################################################################################
		#Modified this function on 8/4/2006 by Anuva technologies for the enhancement of VA2.
		#Add the if..else loop for changing the format of the Installpath and logdir field for running in the MySql enviornment.
		#For MySql it will enter the data into the database when there is double \\.
		################################################################################
		if ($hup{DBTYPE} =~ /MYSQL/)
		{
		$installpath =~ s/\\/\\\\/g; 
		$sqlstr = "insert into sft_elmnt(sft_elmnt_id,type,description,name,host,installdir,exe,service_name,logdir,parent_elmnt_id) values ($maxid,'vlsm','Virtual Administrator Local Service Monitor','LSM','$host','$installpath','v2lsm.exe','v2lsm','$installpath\\\\log\\\\',$ccid)";
		}
		else{

			$sqlstr = "insert into sft_elmnt(sft_elmnt_id,type,description,name,host,installdir,exe,service_name,logdir,parent_elmnt_id) values ($maxid,'vlsm','Virtual Administrator Local Service Monitor','LSM','$host','$installpath','v2lsm.exe','v2lsm','$installpath\\log\\',$ccid)";
		}
		
		$lh->log_print($sqlstr);
		
		
		if ($ccid) {

			eval {
				$sel = $dbh->prepare($sqlstr);
				$sel->execute(); 
				$lh->log_print("Insert SQL = " . $sel->{Statement} );
			};
			if ($@) {$lh->log_print("print error: $@")}

		} else {			
				$lh->log_fail("COULD NOT LOCATE AN INSTALLED CENTRAL SERVICE.  TERMINATING.");
		}
	}
}




sub insertpid{#db session, @componentlist)
my $rethash;
my ($pid,$sft_elmnt_id) = @_;

$lh->log_print("Tracking Pid: $pid for Software Element: $sft_elmnt_id");

#############
#insert
############


		eval {
		$sel = $dbh->prepare( "select pid \"pid\" from processes where pid = $pid and host = '$host'");
		$sel->execute;
		}; 

		if ($@) {$lh->log_print("SQL ERROR: $@")}
		
		while (@pidrow = $sel->fetchrow_array) {
			$duppid = $pidrow[0];
		}


		eval {
		$sel = $dbh->prepare( "select max(process_id) \"increment\" from processes");
		$sel->execute;
		};
		if ($@) {$lh->log_print("SQL ERROR: $@")}
		
		while (@maxrow = $sel->fetchrow_array) {
			$maxid = $maxrow[0];
		}
		
		$maxid++;
		


	unless ($duppid) {

		
		eval {
			$SqlStatement = "insert into processes (process_id,host,pid,sft_elmnt_id) values ($maxid,'$host',$pid,$sft_elmnt_id)";
			$lh->log_print($SqlStatement);

			$sel = $dbh->prepare($SqlStatement);
			$sel->execute;
		};

		if ($@) {$lh->log_print("SQL ERROR: $@")}

	}


}


sub sendwatchermsg {
	my $msg = shift;
	open(MSGFILE,">>$installpath/msg/msgfile.txt") || $lh->log_print("ERROR OPENING MSGFILE: $@");
	print MSGFILE "$msg\n";
	close MSGFILE or $lh->log_print("ERROR CLOSEING MSGFILE: $@");
}


sub isnot_expired {
	$Registry->Delimiter("/");
	my $alreadyexpired = $Registry->{"LMachine/Software/Microsoft/MngUtil//expired"};
	my $licerr = &getlicense(); #check valid license
	if (!$licerr) {#there is no licenserror ie valid license, so return immediately
		return 1;
	} 
	#$alreadyexpired
	unless ($alreadyexpired) {
		my $alreadyhasdate = $Registry->{"LMachine/Software/Microsoft/MngUtil//Idate"};
		print "date = $alreadyhasdate\n";
		my ($smonth,$sday,$syear) = split(/\//,$alreadyhasdate);
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
														localtime(time);
		my $delta = Date::Calc::Delta_Days(   $syear,$smonth,$sday,$year + 1900,$mon + 1,$mday,);
		print "delta = $delta\n"; 
		if ($delta > 90) {
				
				
				#then go on seting expired to true
				print "expired date...\n";
					$Registry->{"LMachine/Software/Microsoft/"} = {
					"MngUtil/" => {
						"/expired" => "true"},
				};
				return 0; #expired, no valid license

		} else {
			return 1; #not expired
		}
	} 
	#expired, don't check date 
	#if we got here, must be a license error too so print it
	$lh->log_print($licerr);
	return 0; 
}

#check license
sub getlicense {
	my $error;
	my $ok;
	open (LIC,"< $curdir/va2.lic") or $error = "CRITICAL ERROR - COULD NOT LOCATE VA2 LICENSE FILE\n";
	unless ($error) {
		while(<LIC>) {
			chomp $_;
			if (crypt($ENV{ComputerName},"va") eq $_) {
				print "AUTHENTICATION PASSED for $ENV{ComputerName} ! \n";
				$ok = 1;
			} else {
				$error = "CRITICAL ERROR - LICENSE $_ NOT FOUND TO BE VALID\n";	
			}
		}
	
	}#
	close LIC;
	unless($ok) {
		unless ($error) {
			#if there isn't an error, set one, becaue oK wasn't set to true
			$error = "CRITICAL ERROR - NO VALID LICENSE FOUND\n";
		}
	}
	return $error;
}


package main;



# any additional support code can go here

