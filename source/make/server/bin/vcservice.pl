package PerlSvc;
use Win32; 
use Log::Logger;
use Win32::Process;
use Cwd 'abs_path';	    # aka realpath()
use vadmin::vconfig;
use Win32::Process;
use Win32;

use IO::Socket;
use IO::Select;
use Win32::TieRegistry;
use Date::Calc;

use DBI;
use DBD::ODBC;
use Win32::Service;
	
my $host = Win32::NodeName;
my %running;
my %externalpids; #do not try to restart these pids, but kill them on shutdown


# these variables cannot be 'my'
$Name = 'vcservice';
$DisplayName = 'Vadmin2 Central Server Service';

#Startup(); #commented Startup() function, this should only be called by NT Service
 
sub Startup {

	$Registry->Delimiter("/");
	$installpath = $Registry->{"LMachine/Software/Recursive Technology/VCS//Install Path"};
	$curdir = "$installpath/bin"; #install dir is assigned from 
     
	



	startappservers($lh);

	$lh->log_print("Startup complete");
	while(ContinueRun()) {

#		if ($debug) {$lh->log_print("checking procs....")};
		 
#				foreach $mk (keys %running) {
#				if ($debug) {$lh->log_print("key = $mk")};
#
#					if (Win32::Process::Open($nhandle,$mk,1)){
#
#						if ($debug) {$lh->log_print("process $mk running")};
#						undef $nhandle;
#			 
#					}else {
#						$lh->log_print("starting up failed task $mk");
#						spawnprocs(@{$running{$mk}});
#						delete $running{$mk};
#					}	
#				}
			
		   if ($hup{AUTOSTARTVLSM}) {		   	 	 
			 if ($debug) {$lh->log_print("checking services....")}
			 &check_services();
		   }
			$sel2 = new IO::Select($ccsocket);
			 if ($sel2->can_read(10)) { #wait up to 60 seconds for a new connection...equivalant to sleep
					my $session = $ccsocket->accept; #new connection
					while (<$session>) {  #get data

							if ($debug) {$lh->log_print("MESSAGE RECIEVED: $_")};
							if ($_ =~ /(\w+): (\d+)/) {#find a word, a : space and number
								
								print("Recieved a External PID Request: $1: $2");
								mvexternalpid($1,$2);  #add this to the external pid list - this PIDs will be killed on shutdown of service
							} elsif ($_ =~ "CCOK") {
								
									my ($message,$host,$lsmport) = split(/:/,$_);	
									#send_to_lsm($message,$host,$lsmport);
									eval {											
										 $sock = IO::Socket::INET->new(
																	Proto=>'tcp',
																	PeerAddr=>$host,
																	PeerPort=> $lsmport,
																) or die $@;					
										};
										if ($@) {
											$lh->log_print("SOCKET ERROR: COULD NOT CONTACT LSM - $host:$lsmport -  $@\n ");
											close $session;
										} else {
											if ($sock) {
												$sock->autoflush(1);
												$sock->send("ISLSMOK\n");
											while (<$sock>) {
													print "got a message back!!$_\n";
													if ($_ = /VLSMISOK/) {
														print $session "VLSMISOK\n";
														close $sock;
													}														
												}
											} else {
												$lh->log_print("SOCKET ERROR FROM VLSM: $@\n");
												print $session "V2LSMNOTOK\n";
												close $sock;
											 }
										 } 
							} elsif ($_ =~ "RESTART APPLOG WATCHER") {

										my ($message,$host,$lsmport) = split(/:/,$_);
										
									eval {											
										 $sock = IO::Socket::INET->new(
																	Proto=>'tcp',
																	PeerAddr=>$host,
																	PeerPort=> $lsmport,
																) or die $@;					
										};

										if ($@) {
											print("SOCKET ERROR: COULD NOT CONTACT LSM - $host:$lsmport -  $@\n ");
											close $session;
										} else {

											if ($sock) {
												$sock->autoflush(1);
												$sock->send("RESTART APPLOG WATCHER\n");
											
												
												while (<$sock>) {
													print "got a message back!!$_\n";
													if ($_ = /OK RESTARTING APPLOG WATCHER/) {
														print $session "VLSMISOK\n";
														close $sock;
													}														
												}
											} else {
												$lh->log_print("SOCKET ERROR FROM VLSM: $@\n");
												print $session "V2LSMNOTOK\n";
												close $sock;
											 }
										 } 
							} #END ELSEIF
						close $session;
					}#end while session
			 }#end can read
		} #end continue run
			
####################### SHUTDOWN SECTION
		foreach $mk (keys %running) {
			$lh->log_print("On Shutdown killed PID $mk");
			killpid($mk,$lh);
		}
		foreach $mk (keys %externalpids) {#kill the external pids
			$lh->log_print("On Shutdown killing External PID $mk");
			killpid($mk,$lh);		
		}
		$sel->finish;
		$lh->log_print("FINISHED THE SOCKET SELECTION");
		#$dbh->disconnect; 
		$dbh = undef;
		$sel = undef;
		#$lh->log_print("DISCONNECTED FROM THE DATABASE");
		close($ccsocket);
		$lh->log_print("SHUTDOWN SOCKET");
		$lh->log_print("GRACEFULL SHUTDOWN COMPLETE");
} 


sub Install {
	#print "begining install....\n";
	$Registry->Delimiter("/");
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
	
    # add your additional install messages or functions here
    #print "\nAdditional install notes\n";
}

sub Remove {
    # add your additional remove messages or functions here
    #print "\nAdditional remove notes\n";
	$host = Win32::NodeName;
	$Registry->Delimiter("/");
	$installpath = $Registry->{"LMachine/Software/Recursive Technology/VCS//Install Path"};
	$lh = new Log::Logger $installpath . "/log/vcservice.log" || new Log::Logger "vcservice.log";
	if ($debug) {$lh->log_print("Install Path : $installpath")}
	
	eval {
	 	if (checkerror(%hup = vadmin::vconfig::openlog("$installpath/bin"))) {die;}  # create user preference hash or die
	};

	if ($@) {$lh->log_print("could not open cofig file, vadmin.config - $@")};
	$temp1;


	if ($debug) {
			foreach $key (keys %hup) {
			$lh->log_print("hup $key = $hup{$key}"); 
			}
		}
	
#########################################################
#Try up to 4 times to  to start db session
#
	for ($i =0 ;$i < 4 ;$i++) { #try up 4 times to connect to db....
		if ( &dbconnect() ) {
			$i = 4;
		} else  {
			sleep (10)
		}

	}



	$sel = $dbh->prepare("delete  from sft_elmnt where type = 'v2centralserver' and host = '$host'");
	if ($@) {$lh->log_print("print error: $@")}
	$sel->execute;

	$lh->log_print("Removed Central Server Service.......");
	
	$sel->finish;

	$dbh->disconnect; 
	$ccsocket->shutdown;

	$lh->log_print("Removal Complete");

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

	

	$lh = new Log::Logger $installpath . "/log/vcservice.log" || new Log::Logger "vcservice.log";


	if ($debug) {$lh->log_print("Install Path : $installpath")}

	eval {
	 	if (checkerror(%hup = vadmin::vconfig::openlog("$installpath/bin"))) {die;}  # create user preference hash or die
	};

	if ($@) {$lh->log_print("could not open cofig file, vadmin.config - $@")};
	
	if ($debug) {
			foreach $key (keys %hup) {
			$lh->log_print("hup $key = $hup{$key}"); 
			}
		}

	
	unless (&isnot_expired()) { #&isnot_expired()= 1 if its not expired, 0 if it is expired
		$lh->log_print("VA2 TRIAL LICENSE HAS EXPIRED. CONTACT www.recursivetechnology.com TO OBTAIN A PRODUTION LICENSE");
		die; #VA2 is no longer freeware! 4/14/2005	
	}
	
#########################################################
#Try up to 4 times to  to start db session
#
	for ($i =0 ;$i < 4 ;$i++) { #try up 4 times to connect to db....
		if ( &dbconnect() ) {
			$i = 4;
			$lh->log_print("Data Session initialized.......");
		} else  {
			sleep (30)
		}
	}

######################################################
# Install the central service
#
	&insertcentralservice();

################################################

	$port = $hup{CCSERVICEPORT} || "15200";
	$ccsocket = IO::Socket::INET->new(Listen => 20,LocalPort => $port) or $lh->fail("CENTRAL SERVER SOCKET ERROR:  $@");
	
	$lh->log_print("LISTENING ON PORT $port");
	


	my $selstr = "update sft_elmnt set port = $port where host = '$host' and type = 'v2centralserver'";
	if ($debug) {$lh->log_print($selstr)}
	
	eval {
	$sel = $dbh->prepare($selstr);
	$sel->execute;
	};

	if ($@) {$lh->log_print("print error: $@")}
	
	$lh->log_print("Curdir = $curdir");

	spawnprocs("$curdir/vcs.exe ",undef,$lh); #central service
	spawnprocs("$curdir/vsar.exe ",undef,$lh); #statisical analysis router
	
  }
	
####################################################################
#start spawnprocs
###################################################################

sub spawnprocs {  
    my ($arg1,$arg2,$lh) = @_;

	my $retpid = &nonforkingsub($arg1,$arg2,$lh);
	if ($retpid =~ "ERROR") {
		
		$lh->log_print("system was not able to start $arg1,$arg2 - will not re-attempt");
		}
	else{
		$running{$retpid}=[$arg1,$arg2];
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
#sub addexteranlpid
###################################################################

sub mvexternalpid {
	my $operation = shift;
    my $expid = shift;

	if ($operation =~ /ADD/) {
		$externalpids{$expid} = $expid;
	}
	
	if ($operation =~ /REMOVE/) {
		delete $externalpids{$expid};
	}

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
	eval {
	Win32::Process::KillProcess($pid, $exitcode) || ErrorReport($lh);
	};
 
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


sub insertcentralservice {



####################################################################33
# Insert HOST
#
	$sel = $dbh->prepare("select hostname \"hostname\" from host where hostname = '$host'");
	if ($@) {$lh->log_print("print error: $@")}
	$sel->execute;

	while( @row = $sel->fetchrow_array ) {
		push @hosts,$row[0];
		print "Row = $row[0]\n";
		print "Array =  @row\n";
	}	

	unless (@hosts) {
		$sel = $dbh->prepare("select max(host_id) + 1 \"host_id\" from host");
		$sel->execute;
		while (@row = $sel->fetchrow_array) {
			$maxid = $row[0];
		}

		unless ($maxid) {
			$maxid++;
		}

		$sqlstr = "insert into host(host_id,hostname) values ($maxid,'$host')";
		$lh->log_print($sqlstr);

		$sel = $dbh->prepare($sqlstr);
				$sel->execute(); 
				$lh->log_print("Insert SQL = " . $sel->{Statement} );
	}

###########################################################################
# Install Central Service if it does not exist

	$sel = $dbh->prepare("select sft_elmnt_id \"sft_elmnt_id\" from sft_elmnt where type = 'v2centralserver' and host = '$host'");
	if ($@) {$lh->log_print("print error: $@")}
	$sel->execute;
	
	while( @row = $sel->fetchrow_array ) {
		push @centralservers,$row[0];
		print "Row = $row[0]\n";
		print "Array =  @row\n";
	}	

	unless (@centralservers) {#if true, there is not at least one central server, so insert one
	
		#get max sft_elmnt_id
		#insert new central server into vadmindb - under vadmin software management system
		eval {
			$sel = $dbh->prepare("select sft_mng_sys_id \"sft_mng_sys_id\" from sft_mng_sys");
			$sel->execute;
			while (@row = $sel->fetchrow_array) {
				$maxsysid = $row[0];
			}
		};

		if ($@) {$lh->log_print($@)}

		#if there is no software management system, insert one and default values
		unless ($maxsysid) {
			$maxsysid++;
			# CO - 10/4/2007 Changed added into to the insert statement
			$sqlstr = "insert into sft_mng_sys(sft_mng_sys_id,name,type) values ($maxsysid,'Virtual Administrator 2','VA2')";
			$lh->log_print($sqlstr);
		
			eval {
				$sel = $dbh->prepare($sqlstr);
				$sel->execute();
				$lh->log_print("Insert SQL = " . $sel->{Statement} );
			};

			if ($@) {$lh->log_print($@)}

			#Insert 60 second default for system interval
			# CO - 10/4/2007 Changed added into to the insert statement
			$sqlstr = "insert into system_msg (system_msg_id,type,message) values ($maxsysid,1,60)";
			$lh->log_print($sqlstr);
		
			eval {
				$sel = $dbh->prepare($sqlstr);
				$sel->execute();
				$lh->log_print("Insert SQL = " . $sel->{Statement} );
			};
			if ($@) {$lh->log_print($@)}
		}
		$sel = $dbh->prepare("select max(sft_elmnt_id) + 1 \"sft_elmnt_id\" from sft_elmnt");
		eval {
			$sel->execute;
			while (@row = $sel->fetchrow_array) {
				$maxid = $row[0];
			}
		};

		if ($@) {$lh->log_print($@)}
		
		unless ($maxid) {
			$maxid++;
		}
		##################################################################################
		#Modified this function on 8/4/2006 by Anuva technologies for the enhancement of VA2.
		#Add the if..else loop for changing the format of the Installdir and logdir field for running in the MySql enviornment.
		#For MySql it will enter the data into the databse when there is double \\.
		##################################################################################

		if ($hup{DBTYPE} =~ /MYSQL/)
		{
		$installpath =~ s/\\/\\\\/g; 
		$sqlstr = "insert into sft_elmnt(sft_elmnt_id,type,description,name,host,installdir,exe,service_name,logdir,sft_mng_sys_id) values ($maxid,'v2centralserver','Virtual Administrator Central Server','Central Server','$host','$installpath','vcservice.exe','vcservice','$installpath\\\\log\\\\',1)";
		}
		else{

			$sqlstr = "insert into sft_elmnt(sft_elmnt_id,type,description,name,host,installdir,exe,service_name,logdir,sft_mng_sys_id) values ($maxid,'v2centralserver','Virtual Administrator Central Server','Central Server','$host','$installpath','vcservice.exe','vcservice','$installpath\\log\\',1)";
		}
		$lh->log_print($sqlstr);
		
		eval {
			$sel = $dbh->prepare($sqlstr);
			$sel->execute(); 
			$lh->log_print("Insert SQL = " . $sel->{Statement} );
		};
		if ($@) {$lh->log_print($@)}


	}
	$sel = undef;
	foreach (@localappservers) {
		print "SERVER = $_\n";
		$incid++;
		$lh->log_print("app $incid = $_"); 
		spawnprocs("$curdir/vsrvrmgr.exe ","$_ $incid ",$lh);
		spawnprocs("$curdir/vlogmon.exe ","$_ ",$lh); # log monitor
	} 

}


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

###########################################################
# Check Services sub
###################################################

sub check_services {	
	my %services;
	if ($debug) { $lh->log_print("Checking VLSM Services....") }
	$sel = $dbh->prepare("select service_name \"service_name\" ,host \"host\" from sft_elmnt where type = 'vlsm'");
	if ($@) {$lh->log_print("print error: $@")}
	$sel->execute;
	while( @row = $sel->fetchrow_array ) {
		$services{$row[0]} = $row[1];
	}	
	#loop through each vlsm service
	foreach $svcname (keys %services) {
		my %status;
		my $trystart;
		my $servicehost  = $services{$svcname};
		$servicehost =~ s/\s*$//; #trim trailing spaces
		$svcname  =~ s/\s*$//;
		if ($debug) {$lh->log_print("Checking Running Status for Service: Service = $svcname, Host = $servicehost") } ;
		Win32::Service::GetStatus($servicehost,$svcname, \%status);
			unless ($status{"CurrentState"} == 4) {
				$lh->log_print("LSM SERVICE: $svcname IS NOT RUNNING ON $servicehost.");
				#removed the auto start wierdness
				$trystart = Win32::Service::StartService($servicehost,$svcname) || $lh->log_print("Can't start service $svcname");
				#print "trystart = $trystart\n";
			} 
			if ($trystart or $status{"CurrentState"} == 4) {
				if ($debug) {$lh->log_print("Service: Service = $svcname, Host = $servicehost Successfully Started.")}
			}
	}
}

###########################################################
# Check Services sub
###################################################

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

