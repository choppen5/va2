#!d:\perl\bin\perl  

use strict;
use vadmin::vconfig;
use vadmin::data1;
use Log::Logger;

use vadmin::srvrmgr;
use Win32::Service;
use Win32;
use Array::Compare;

use IO::Socket;
use IO::Select;

use Win32::IProcess qw(
PROCESS_QUERY_INFORMATION PROCESS_VM_READ INHERITED INHERITED DIGITAL NOPATH
); 
use Frontier::Client;


my $host = Win32::NodeName;     	

my $refe;
my %qhoa;

my %srvmgrvars;
my %cmd;
my $key;
my $server_id;

use vars qw(%hup $datasession $dbreconnect);

%main::hup;    #hash of user preferneces
$main::datasession;
$main::dbreconnect;

my $svrmgrpid; #variable will hold process id spawned for srvrmgr


use Cwd 'abs_path';	    # aka realpath()
my $rootpath = abs_path("..");

my $nosiebel; #CO 9/3/2007 - added variable for a non Siebel Server srvrmgr
my $siebsrvr = $ARGV[1] || ($nosiebel = 1);
print "nosiebel = $nosiebel\n";

print "log path =  $rootpath/log/vsrvrmgr".$siebsrvr.".log\n"; 

#&vadmin::vconfig::removelog();			 #rename old log files "time()".logbak


my $db = 'MSSQL';

my $lh = new Log::Logger "$rootpath/log/vsrvrmgr".$siebsrvr.".log" || new Log::Logger "./vsrvrmgr".$siebsrvr.".log"  ;				# global log file
$lh->log_print("Start up.......");             # first log comment

my $instid = ($ARGV[2] || 1); # CO 9/3/2007 - changed to take no required parameters # $lh->fail("Command line args incorrect - use: vsrvrmgr.exe siebsrvrname instid");  # shift in the siebel server



#########
#get command line siebsrvr
#########

#fatal error
if (checkerror(%hup = vadmin::vconfig::openlog())) {die;}  # create user preference hash or die

my $debug = $hup{DEBUG};
my $dontfilltasks = $hup{NOTASKS};
my $restartpause = $hup{RESTARTPAUSE} || 60; #by default, pause for 60 seconds on siebel server restart before starting siebserver serversession
my $startpause = $hup{STARTPAUSE} || 0; 
my $dbreconnect = $hup{DBRECONNECT} || 60;
my $lsmport =$hup{VLSMPORT};
my $harvestpause =$hup{HARVESTPAUSE}; #set param in config file when spooling tasks take a long time
my $growthwait = $hup{GROWTHWAIT};

#added 4/9/2006 to allow individual settings on siebel collection routines - if params arent set, use harvestpause and growthwait
my $collectsiebelsession = $hup{COLLECTSIEBELSESSION};
my $siebelsessiontimeout = $hup{SIEBELSESSIONTIMEOUT} || $harvestpause;
my $siebelsessiongrowthtime = $hup{SIEBELSESSIONGROWTHTIME} || $growthwait;

my $siebeltasktimeout = $hup{SIEBELTASKTIMEOUT} || $harvestpause;
my $siebeltaskgrowthtime = $hup{SIEBELTASKGROWTHTIME} || $growthwait;

my $siebelcomptimeout = $hup{SIEBELCOMPTIMEOUT} || $harvestpause;
my $siebelcompgrowthtime = $hup{SIEBELCOMPGROWTHTIME} || $growthwait;

#added 4/15/2006 - Allow users to set the TASKRESET time.  If the collection period is set to 300 seconds for example, you would want to reset tasks every 6 cycles or roughly every hour
my $taskresetcycles = $hup{TASKRESETCYCLES} || 60; #defaults to 60

if ($debug) {
	foreach $key (keys %hup) {
	$lh->log_print("hup $key = $hup{$key}"); 
	}
}

my $url  = "http://$hup{CENTRALSERVER}:$hup{CCPORT}/RPC2";
my $client; 

&startfrontier;

sub startfrontier {

	$client = Frontier::Client->new( url   => $url,
					debug => $debug,
				  );

}


#fatal error


$datasession = vadmin::data1::odbcsess($debug,$lh,$hup{VODBC},$hup{USERNAME},$hup{PASSWORD}) ;


$lh->log_print("Data Session initialized.......");

if ($hup{DBTYPE} =~ /ORACLE/) {
 vadmin::data1::alterdateformat($datasession,$debug,$lh);
}
#
############################
# IP ADDRESS


my $taskreset = $hup{TASKSYNC};

my $port =  $ARGV[0] || $hup{VSRVRMGRPORT} || "15210";
$lh->log_print("Attempting to listen on port: $port");
my $ccsocket;

my $try;
for ($try=0;$try<10;$try++) {
	
	$ccsocket = IO::Socket::INET->new(Listen => 20,LocalPort => $port) or $lh->log_print("ERROR GETTING SOCKET ON PORT $port: $@");#	
	if ($ccsocket) {
		#send back some info about port
			$lh->log_print("SUCCESSFULLY USED SOCKET ON PORT $port: Sending socet information to VLSM");

		 	eval {
				my $lsmsock = IO::Socket::INET->new(Proto=>'tcp',PeerAddr=>"$host:$lsmport") or die $@;
				$lsmsock->send("VSRVRMGRPORT:$port\n");
				$lh->log_print("Sending back VSRVRMGRPORT:$port for shutdown procedure.");
				sleep(1);
			};		
		$try=10;
	}		
	#try next port
	$port++;
}

unless($ccsocket) {
 $lh->fail("ERROR GETTING SOCKET: $@");
}
my $sel2; #socket
###########################################################
# vpid mon global vars

my($obj)=new Win32::IProcess || die "Can not create an IProcess object..\n";
my @pids;
my @running;
my %prevrunning;

my $pidcompare = Array::Compare->new;


my $server  = ("\\\\$host");
my $service; #used for constructing the siebel service name
my $check   = ("CurrentState");
my %status;
my $comp = Array::Compare->new;
my %prevcomphash;
my %prevtaskhash;
my %prevsessionhash;
#updated 4/16/2006 - for adding more logic in memory and reducing DB calls
my %savedtasks;			# resides in memory, tracks siebel tasks
my %savedsessions;		# resides in memory, tracks siebel sessions

#################
# 9/3/2007 - modified to only do Siebel stuff if a Siebel appserver paramater is passed in

if ($nosiebel != 1) {
		#do all the siebel stuff unless this a $nosiebel srvrmgr
			##########################################################
			%srvmgrvars = vadmin::data1::getinitvars($datasession,$debug,$lh,$siebsrvr);
			$service = ("siebsrvr_" . $srvmgrvars{enterprise} . "_".$siebsrvr);
			if ($debug) {
				foreach $key (keys %srvmgrvars) {
					$lh->log_print("srvmgrvars $key = $srvmgrvars{$key}");
				}
			}

			if ($startpause) {
				$lh->log_print("Starting the vsrvmgr service - pausing $startpause seconds on startup due to STARTPAUSE parameter being set in config db");
				sleep($startpause);
			}

			print "harvestpause = $harvestpause\n";


			$refe = vadmin::srvrmgr->new($lh,$srvmgrvars{gatewayhost},$srvmgrvars{enterprise} , $srvmgrvars{LOGIN}, $srvmgrvars{PASSWORD}, $srvmgrvars{server_name}, $srvmgrvars{serverpath},$instid,undef,$harvestpause,$growthwait);
											
			$server_id = $srvmgrvars{server_id};
			$refe->startsession;
			$svrmgrpid = $refe->{PID};
			pidtolsm($svrmgrpid,"VPIDADD");

			$lh->log_print("Srvmgr Session initialized.......PID = $refe->{PID}");
			$lh->log_print("status = $refe->{STATUS}\n");
			$lh->log_print("Server Id = $server_id");

			#clean stuff up on startup just in case
			&vadmin::data1::deletecomps($datasession,$hup{DEBUG},$lh,$siebsrvr);
			&vadmin::data1::deletetasks($datasession,$hup{DEBUG},$lh,$server_id);
			&vadmin::data1::deletesessions($datasession,$hup{DEBUG},$lh,$server_id);
} else {
	$lh->log_print("Starting a srvrmgr session for a Non Siebel Server instance.");
}


###################################################################################################################################################
#Main Loop
#
my $i = 0;
my $restarted;
my $cyclecount;

while (1) { #main loop
my $interval = &vadmin::data1::getinterval($datasession) ||  30; #default interval
if ($debug) {$lh->log_print("interval = $interval")};

$cyclecount++;
if ($debug) {$lh->log_print("Running vsrvrmgr - interval = $taskresetcycles - cycle count = $cyclecount")};

	if ($cyclecount > $taskresetcycles) {

		$lh->log_print("Resetting at inverval = $taskresetcycles");
		$taskreset=1;
		%prevcomphash = undef;
		#%prevtaskhash = undef;
		$cyclecount=0;

	} else {

		$taskreset=0;
	}
	#check to see if server is running before running thise items

	# CO 9/3/2007 - changed to determine if we are a non Siebel server instance
	if ($nosiebel == 1) {

		&check_services;
		&getnex;

	} else {
			# 9/3/2007 - do all this for seibel situations
			if (&checksiebsrvr()) {
				
					#if we've been restarted, the session needs to be restarted before filing comps etc.	
					#this is the main loop for vsrvmgr, fires in order those below
					#&getsysroutedmsg;
					#&fillcomps;
					#&pidprocess;
					#&check_services;
					#&getnex;

					#route reactions first, ie start components before harvesting pid information
					#change 7/12/2005 - fires the reaction stuff, for example restart a component, then waits before harvesting component info to get info
					&getsysroutedmsg;
							  
					 if ($restarted) {
							#give the Siebel server some time before starting up
							$lh->log_print("Siebel Server has been Restarted - waiting $restartpause seconds before starting new session");
							sleep($restartpause);

							$refe->startsession;
							$svrmgrpid = $refe->{PID};
							pidtolsm($svrmgrpid,"VPIDADD");

							$restarted = 0;
					  }

					  &fillcomps;
					  
					  if ($dontfilltasks != 1) {
						 #if users set the NOTASKS parameter = 1, don't harvest server tasks - due to really long time for server manager harvesting
						&filltasks;					  
					  } 	  
					  
					  if ($collectsiebelsession) {
						  &fillsessions;
					  }

					if ($taskreset == 1) {
						#stop and restart siebel server session
						&stopandrestartsrvrmgrsession;
					}

				
				} else {  #siebel server is not running, so clean up any old info in the tables
					
					#only delete comps as it uses old system
					&vadmin::data1::deletecomps($datasession,$hup{DEBUG},$lh,$siebsrvr);
					&vadmin::data1::deletesessions($datasession,$hup{DEBUG},$lh,$server_id);
					&vadmin::data1::deletetasks($datasession,$hup{DEBUG},$lh,$server_id);
					$restarted = 1;

				}
				  #pid stuff					
					&pidprocess;
					&check_services;
					&getnex;
	} ## End $nosiebel -  else check. do all below for both siebel and non siebel situations

			$sel2 = new IO::Select($ccsocket);

			 if ($sel2->can_read($interval)) {			#wait up to $interval seconds for a new connection...equivalant to sleep
					my $session = $ccsocket->accept;	#new connection

					while (<$session>) {  #get data
							if ($_ =~ /EXITNOW:/) {#EXIT SRVRMGR COMMAND
								
								$lh->log_print("Recieved a EXITNOW");
								
								$refe->sendcommand("exit\n");
								pidtolsm($svrmgrpid,"VPIDREMOVE");

								$lh->log_print("Routed exit command");
								
								$ccsocket->shutdown(2);
								$lh->log_print("shutdown socket");
								close($ccsocket);
								$lh->log_print("Closed Socket");

								

								$datasession->Close(); 
								$lh->log_print("Closed Database Connection");

								$lh->log_print("SHUTDOWN COMPLETE");
								exit;
								#
							}
					}
					close $session;
					print "Closed session...\n";
			 }
	print "finished wait for ip message\n";

} #end while, for main loop

###########################################################################################################################################
sub getsysroutedmsg{

	my @sysmessages = vadmin::data1::getsyssrvrmgrcmds($datasession,$debug,$lh,$siebsrvr);	
	my $firedreaction;

	for my $i (0..$#sysmessages) {
		my $ruledeff = vadmin::data1::getruledef($datasession,$debug,$sysmessages[$i]{message}) || $lh->log_print ("no reaction deffinition found for rule $sysmessages[$i]{message}\n");
		srvrcmd("$ruledeff\n",2,1);  #send growthwait and harvest time for reactions - these will always time out so set it to 2 secs
		$lh->log_print("Sent Command as reaction: $ruledeff");
		#add to reaction history?
		vadmin::data1::deletsysmsg($datasession,$debug,$lh,$sysmessages[$i]{system_msg_id});
		$firedreaction = 1;
	}
	if ($firedreaction) {
		sleep(5); #if we've fired a reaction, wait 3 seconds before the component and task collection routines start
	}
}

#sub


######################### SUB FILLCOMPS   #################################
sub fillcomps {

if ($debug) {$lh->log_print("HARVESTING SIEBEL COMPONENT STATUS")};														
my $compcount;
my %myhsh = srvrcmd("list components for server $srvmgrvars{server_name}\n",$siebelcomptimeout,$siebelcompgrowthtime);


my ($i,$row);
	if (%myhsh) {
	   if ($taskreset) {#clean up existing tasks
			&vadmin::data1::componentclean($datasession,$hup{DEBUG},$lh,$server_id,%myhsh); 						
	   }	

		for $i (0..$#{$myhsh{"ROWS"} }){
								for $row($myhsh{"ROWS"}[$i]) {

												if (%prevcomphash) {#will be untrue on first run
													if ($comp->compare(\@{$prevcomphash{ROWS}[$i]},\@$row)) {
														if ($debug) {$lh->log_print("MATCHES COMPONENT ARRAY - DO NOT INSERT @$row")};													
													} 
													
													else { # does not match, insert record													 
																if ($debug) {$lh->log_print("NO MATCH COMPONENT ARRAY - INSERT @$row ")};
																&vadmin::data1::componentprocess($datasession,$hup{DEBUG},$lh,$srvmgrvars{"server_id"},undef,@$row);
															 }		 
												} 
												else { #no previous hash, insert everything
													if ($debug) {$lh->log_print("NO MATCH COMPONENT ARRAY -INSERT @$row ")};
													&vadmin::data1::componentprocess($datasession,$hup{DEBUG},$lh,$srvmgrvars{"server_id"},undef,@$row);
												}

								}#end for $row
		} #end for $i
		%prevcomphash = %myhsh;
	} else {	
			#else there is no %myhash returned so do nothing		
	}
	$lh->log_print("FINISHED HARVESTING SIEBEL COMPONENT STATUS");

} #end SUB fill comps


######################### SUB FILLTASKS  #################################
sub filltasks {

my %currentasks; #created every time from %myhash returend from Siebel server

if ($debug) {$lh->log_print("HARVESTING SIEBEL TASK STATUS")};
my $taskcount;
my %myhsh = srvrcmd("list tasks for server $srvmgrvars{server_name}\n",$siebeltasktimeout,$siebeltaskgrowthtime); #pass 1 to specify server task capture

my ($i,$row);
	if (%myhsh) {  		
		if ($debug) {$lh->log_print("Processesing Server Tasks for Inserts or Updates")};
		for $i (0..$#{$myhsh{"ROWS"} }){						
				for $row($myhsh{"ROWS"}[$i]) {
					  my $tk_task_id = @$row[2]; #
					  print "TASK ID = $tk_task_id\n";
					  $currentasks{$tk_task_id} = [@$row];

					  if ($savedtasks{$tk_task_id}) {
						#update?	
						print "derefrencing saved array $savedtasks{$tk_task_id} = " . \@{$savedtasks{$tk_task_id}} . "\n";
							if ($comp->compare(\@{$savedtasks{$tk_task_id}},\@$row)) {
								#array matches, no update necessary
							} else { 
								#update
								&vadmin::data1::taskprocess($datasession,$hup{DEBUG},$lh,$server_id,"UPDATE",$host,@$row);
							}				  
					  } else { #does not match previous row, insert
						 # INSERT
						&vadmin::data1::taskprocess($datasession,$hup{DEBUG},$lh,$server_id,"INSERT",$host,@$row);
						# update hash
						$savedtasks{$tk_task_id} = [@$row];
					  }
				}#end for $row
		} #end for $i
		if ($debug) {
			$lh->log_print("Processesing Server Tasks for Deletes");
			my $tasknum = keys ( %currentasks );
			my $savedtasks = keys ( %savedtasks);
			$lh->log_print("Current Task Number = $tasknum , Saved task number = $savedtasks");
		}
	
		############################################################################################3
		#now we go through all the saved tasks look for ones to delete
		for my $task_id (keys %savedtasks) {
			unless ($currentasks{$task_id} ) {
				#the task is missing in currentask list,delet
				if ($debug) {$lh->log_print("DELETING task id $currentasks{$task_id}")	};
				&vadmin::data1::taskprocess($datasession,$hup{DEBUG},$lh,$server_id,"DELETE",$host,@{$savedtasks{$task_id}} );
				delete $savedtasks{$task_id};
			}
		}

	} else { #no myhash, therefore don't parse - write error here		
		$lh->log_print("ERROR: No server tasks were returned to parse");
	}
	$lh->log_print("FINISHED HARVESTING SIEBEL TASK STATUS");
}
### END SUB FILL TASKS


######################### SUB FILLSESSIONS   #################################
sub fillsessions {

my %currentsessions; #created every time from %myhash returned from Siebel server

if ($debug) {$lh->log_print("HARVESTING SIEBEL SESSIONS")};														
my %myhsh = srvrcmd("list sessions for server $srvmgrvars{server_name}\n",$siebelsessiontimeout,$siebelsessiongrowthtime);


my ($i,$row);
	if (%myhsh) {
		if ($debug) {$lh->log_print("Processesing Sessions for Inserts or Updates")};
		for $i (0..$#{$myhsh{"ROWS"} }){
				for $row($myhsh{"ROWS"}[$i]) {
					my $tk_task_id = @$row[3]; #
					  print "TASK ID = $tk_task_id\n";
					  $currentsessions{$tk_task_id} = [@$row];

					  if ($savedsessions{$tk_task_id}) {
						#update?	
						print "derefrencing saved array $savedsessions{$tk_task_id} = " . \@{$savedsessions{$tk_task_id}} . "\n";
							if ($comp->compare(\@{$savedsessions{$tk_task_id}},\@$row)) {
								#array matches, no update necessary
							} else { 
								#update
								&vadmin::data1::sessionprocess($datasession,$hup{DEBUG},$lh,$server_id,"UPDATE",@$row);
							}				  
					  } else { #does not match previous row, insert
						 # INSERT
						&vadmin::data1::sessionprocess($datasession,$hup{DEBUG},$lh,$server_id,"INSERT",@$row);
						# update hash
						$savedsessions{$tk_task_id} = [@$row];
					  }

				}#end for $row
		} #end for $i
		if ($debug) {
			$lh->log_print("Processesing Sessions for Deletes");
			my $tasknum = keys ( %currentsessions );
			my $savedtasks = keys ( %savedsessions);
			$lh->log_print("Current Session Number = $tasknum , Saved session number = $savedtasks");
		}
		
		############################################################################################3
		#now we go through all the saved SESSIONS to look for ones to delete
		for my $task_id (keys %savedsessions) {
			unless ($currentsessions{$task_id} ) {
				#the task is missing in currentask list,delet
				if ($debug) {$lh->log_print("DELETING Session task id $currentsessions{$task_id}")	};
				&vadmin::data1::sessionprocess($datasession,$hup{DEBUG},$lh,$server_id,"DELETE",@{$savedsessions{$task_id}});
				delete $savedsessions{$task_id};
			}
		}

	} else { #no myhash, therefore don't parse - write error here		
		$lh->log_print("ERROR: No Sessions were returned to parse");
	}
	$lh->log_print("FINISHED HARVESTING SIEBEL SESSION STATUS");

} 
#end SUB fill sessions



###############################################################
#returns 1 if siebel service is running, otherwise 0
sub checksiebsrvr {
	if ($debug) {$lh->log_print("checking siebel service: $service")};
	Win32::Service::GetStatus($server, $service, \%status);
		if ($status{$check} == 4){
			if ($debug) { $lh->log_print("The $service Service is UP") };
			updatesrvrstatus($datasession,$debug,$lh,$server_id,"RUNNING");
			return 1;
		} else	{ 
			if ($debug) {$lh->log_print("WARNING: Service  $service is not running - will not harvest server manager information")}
			updatesrvrstatus($datasession,$debug,$lh,$server_id,"STOPPED");
			$refe->closesession;
			#pidtolsm($svrmgrpid,"VPIDREMOVE");
			return 0;
		}


}




sub svcheckblock { # blocks until service is running

	if ($debug) {$lh->log_print("$server\n$service\n$check")};
	
    my $prevnotrunning;
	my $updatemsg;
	my $notrunning = 1;
	while ($notrunning) {
		Win32::Service::GetStatus($server, $service, \%status);
		if ($status{$check} == 4){
			$lh->log_print("The $service Service is UP - starting Siebel Server Monitoring Session");
				updatesrvrstatus($datasession,$debug,$lh,$server_id,"RUNNING");

				if ($prevnotrunning ) {sleep(45)}#the service just started, give it a while to get up
			$notrunning = 0;					 #this will exit the while
		}else {
			unless ($updatemsg) {
										$lh->log_print("Waiting for $service  Service to Start......\n");
										updatesrvrstatus($datasession,$debug,$lh,$server_id,"STOPPED");
	
										#update server status	
										$updatemsg = 1;
									}
			#adjust global running variables - print something 1 time to log file indicating waiting
			$lh->log_print("The $service Service is not currently running");
			$prevnotrunning =1;  
			sleep(1);
		}
	}	
}




sub srvrcmd {
	my %qhoa;
	my $cmd = shift;
	my $harvestime = shift;
	my $growthwait = shift;
	
	my $runonce = shift;
	my $errorun = shift;

	$refe->{ERROR} = undef; #reset any errors


if ($refe->{STATUS} > 0) {
	$refe->sendcommand($cmd,$harvestime,$growthwait);
	
	# check for errors sending command
	if ($refe->{ERROR}) {
		my $datestring = &getdatestring();
		$lh->log_print("ERROR srvrcmd: $refe->{ERROR}");
		#args = my ($sft_elmnt_id,$server,$event_string,$usr_event_level,$usr_event_type,$usr_event_sub_type,$event_time,$error_defs_id,$cc_alias,$host,$analysis_rule_id) =@_;	
		&senderrortovcs($server_id,$siebsrvr,$refe->{ERROR},0,"VLSM_SIEBELCOMMAND","TIMEOUT",$datestring,undef,undef,$host,undef);
	}

	if ($cmd=~/list tasks for server/) {
		#it is a server task command, pass in parameter
		%qhoa = $refe->parse_results(1);
	} else {
		%qhoa = $refe->parse_results;	
	}
   }
	else {
			if ($runonce < 1) {
				#Changed 12/18/2006 - added growthwait in the right place...
				$refe = vadmin::srvrmgr->new($lh,$srvmgrvars{gatewayhost},$srvmgrvars{enterprise} , $srvmgrvars{LOGIN}, $srvmgrvars{PASSWORD}, $srvmgrvars{server_name}, $srvmgrvars{serverpath},1,$harvestpause,$growthwait);
			    #$refe = vadmin::srvrmgr->new($lh,"localhost",$srvmgrvars{enterprise} , $srvmgrvars{LOGIN}, $srvmgrvars{PASSWORD}, $srvmgrvars{server_name}, $srvmgrvars{serverpath},1);
			
				$refe->startsession;
				$svrmgrpid = $refe->{PID};
				pidtolsm($svrmgrpid,"VPIDADD");


				$lh->log_print("Srvmgr Session attempting restart......");
				$runonce++;				
				srvrcmd($cmd,$harvestime,$growthwait,$runonce)
			}   #recursive funciton!
				return 0;				  #if already attempted to restart and failed - return 0
	}

 if ($qhoa{ERROR} < 30 && $qhoa{ERROR} > 0) {
	   $refe->changestatus($qhoa{ERROR},$qhoa{ERROR});
	   $lh->log_print("ERROR: $qhoa{ERROR}\nERRORSTRING: $qhoa{ERRORSTRING}");
	   $refe->closesession;
	   pidtolsm($svrmgrpid,"VPIDREMOVE");

		%prevcomphash = undef;
		%prevtaskhash = undef;
		&vadmin::data1::deletetasks($datasession,$hup{DEBUG},$lh,$server_id);
		&vadmin::data1::deletecomps($datasession,$hup{DEBUG},$lh,$siebsrvr);
		#&svcheckblock;
	   if ($errorun < 1) {
	   $errorun++;				
	   srvrcmd($cmd,$harvestime,$growthwait,undef,$errorun)}
	   return 0;
   }

print "sent command - returning %qhoa\n";
   return %qhoa;
}


###############################################################
#sub pid process calls printprocess, which colects data on pids
#

sub pidprocess {
	my $pid;
	my $pidrun;
	@pids = &vadmin::data1::getpids($datasession,$debug,$lh,$host);
	
	@running = (); 

	if ($debug) {$lh->log_print("Gathering PID info from OS")}	
	&printprocesses();
	if ($debug) {$lh->log_print("FINISHED getting OS PID info.")}	

	foreach $pid (@pids) {  #cycle through the pids from the db
		if ($debug) {$lh->log_print("pid = $pid")}

		
		$pidrun = grep(/\b$pid\b/,@running);   #look for db pid in the currently running pids list 
		unless ($pidrun) {                     #if not found, delete db pid
			$lh->log_print("Deleted $pid");
			
			&vadmin::data1::deletepidbypid($datasession,$debug,$lh,$pid,$host);
		}
	}
	if ($debug) {$lh->log_print("FINISHED ALL PID PROCESSING")}	
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
		 # printf("%15.14s%19.18s%19.18s%15.14s%7.6s\n",$EnumInfo[$i]->{ProcessName},
		 #  $TimeInfo->{UserTime},$TimeInfo->{KernelTime},$TimeInfo->{CreationTime},
		 # $EnumInfo[$i]->{ProcessId});
					
			#if ($debug) {$lh->log_print("$EnumInfo[$i]->{ProcessName}:")};
			$obj->GetProcessMemInfo($EnumInfo[$i]->{ProcessId},\$Info);
			if ($debug ) {
				#printf("%11.10s %7.6s %10.9s %15.14s %18.17s %14.13s\n\n",
				#$Info->{PageFaultCount},$Info->{PeakWorkingSetSize},
				#$Info->{WorkingSetSize}/ 1024,$Info->{QuotaPagedPoolUsage},
				#$Info->{QuotaNonPagedPoolUsage},$Info->{PagefileUsage}/1024);
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
	
							
							if ($debug) {
										  $lh->log_print("Process Id = $EnumInfo[$i]->{ProcessId}. User seconds = $usersecs. Kernel Seconds = $kernelsecs. CPU Time = $cputime");
							 }
							

						  $obj->CloseHandle($Hnd);	

						if ($taskreset) {

							&vadmin::data1::updatepid($datasession, $debug, $lh,$host,@{$running{$EnumInfo[$i]->{ProcessId}}});	

						}	
							
							
							if (%prevrunning) {#will be untrue on first run
										if ($pidcompare->compare(\@{$running{$EnumInfo[$i]->{ProcessId}}},\@{$prevrunning{$EnumInfo[$i]->{ProcessId}}})) {
											if ($debug) {$lh->log_print("MATCHES ARRAY - DO NOT UPDATE $EnumInfo[$i]->{ProcessId}")};
											
										} 
										
										else { # does not match, insert record
											     
													if ($debug) {$lh->log_print("NO MATCH ARRAY - UPDATE $EnumInfo[$i]->{ProcessId} ")};
													#print "PREVOUS ARRAY = @{$prevrunning{$EnumInfo[$i]->{ProcessId}}}\n";
													#print "NEW ARRAY = @{$running{$EnumInfo[$i]->{ProcessId}}}\n";
												&vadmin::data1::updatepid($datasession, $debug, $lh,$host,@{$running{$EnumInfo[$i]->{ProcessId}}});	
												 
												 }		 
										
									} 
									else { #no previous hash, insert everything
											if ($debug) {$lh->log_print("NO PREVIOUS ARRAY -UPDATE $EnumInfo[$i]->{ProcessId} ")};
										&vadmin::data1::updatepid($datasession, $debug, $lh,$host,@{$running{$EnumInfo[$i]->{ProcessId}}});	
						
									}


							#&vadmin::data::updatepid($datasession, $debug, $lh,$host,@{$running{$EnumInfo[$i]->{ProcessId}}});		
							last;
						}

					}
			if (%prevrunning) {delete $prevrunning{$EnumInfo[$i]->{ProcessId}}}
			$prevrunning{$EnumInfo[$i]->{ProcessId}} = [$EnumInfo[$i]->{ProcessId},$EnumInfo[$i]->{ProcessName},undef,$cputime,$kernelsecs,$usersecs,$Info->{WorkingSetSize}/ 1024,$Info->{PageFaultCount},$Info->{PagefileUsage}/1024,undef,undef];
			%running = undef;

		}

		$obj = undef;
		(@EnumInfo,$i,$Info) = undef;

}


##################################################
#sub getlocal reaction messages
#

sub getnex {
	my $i;
	
	my @sysmessages = vadmin::data1::getlsmxmsg($datasession,$debug,$lh,$host);
	
	
	for $i (0..$#sysmessages) {
			
			my $random = rand 100000;
			my $args= " peval.exe $sysmessages[$i]{message} $sysmessages[$i]{type} > ./reaction_$sysmessages[$i]{message}_".time().$random.".reactionlog";
			
			open(DOSPROMPT, "| $args") or sleep(1) and open(DOSPROMPT, "| $args"); 
			close(DOSPROMPT);
			$lh->log_print("FIRED REACTION REACTION $sysmessages[$i]{message} : $args");
			
			#add reaction history log ?
			vadmin::data1::deletsysmsg($datasession,$debug,$lh,$sysmessages[$i]{system_msg_id});

	}# end for 

}


sub pidtolsm {
	# action VPIDADD or VPIDREMOVE are allowed actions - sends srvrmgr pid to lsm service - lsm will kill it if an exit comand fails for any reason
	my $pid = shift;
	my $action = shift;

		 	eval {
				my $lsmsock = IO::Socket::INET->new(Proto=>'tcp',PeerAddr=>"$host:$lsmport") or die $@;
				$lsmsock->send("$action:$pid\n");
				$lh->log_print("Sending back $action:$pid for shutdown procedure.");
				sleep(1);
			};

}


#################################################################################
#

sub stopandrestartsrvrmgrsession {


	# end server manager session
	$lh->log_print("Stoping servermanager session - in cycle ");
	$refe->sendcommand("exit\n");
	pidtolsm($svrmgrpid,"VPIDREMOVE");


	# start an new server manager session - don't need to get new variables	
	$lh->log_print("RE-Starting servermanager session - in cycle ");
	$refe->startsession;
	$svrmgrpid = $refe->{PID};
	pidtolsm($svrmgrpid,"VPIDADD");
			
}

################################################################################
# Sub check services
################################################################################

sub check_services {

my @sv_names = &vadmin::data1::getaoh(  $datasession, $debug, $lh, "select sft_elmnt_id \"sft_elmnt_id\",service_name \"service_name\", monitor_service \"monitor_service\", restart_service \"restart_service\", send_event \"send_event\" from sft_elmnt where service_name is not null  and host = '$host' and monitor_service = 'Y'" );

my $svname;	
my %status;

	for $svname(@sv_names) {
		my %svhash = %$svname;
		my $trystart = 0;
		
				Win32::Service::GetStatus($host, $svhash{service_name}, \%status);
						if ($status{"CurrentState"} == 4){
							if ($debug) {$lh->log_print("The Service:  $svhash{service_name} is UP")};
							$trystart = 1;
						} else {

							#errorinsert args = ($sft_elmnt_id,$server,$event_string,$usr_event_level,$usr_event_type,$usr_event_sub_type,$time, $error_defs_id,$cc_alias,$host)				
							$lh->log_print("WARNING!! The Service:  $svhash{service_name} is NOT RUNNING.");
							my $datestring = &getdatestring();

							if ($svhash{restart_service} =~ /Y/) {
								my @args = ($svhash{sft_elmnt_id},undef,"WARNING!! The Service:  $svhash{service_name} is NOT RUNNING. Attempting to Restart.",undef,'Service Restart Attempt',$svhash{service_name},$datestring,undef,undef,$host);
								eval{$client->call('errorinsert',@args)};
								if ($@) {
										$lh->log_print("ERROR: Could not report event! :\t $@ Attempting to Reconnect");
										
										&startfrontier;
										#try again to connect...
										eval{$client->call('errorinsert',@args)};

									}

								$trystart = Win32::Service::StartService($host,$svhash{service_name});
							}	
						
						}

			
						unless ($trystart) { #try to send event if service was not started

							$lh->log_print("Did not start service: $svhash{service_name}");
							if ($svhash{send_event} =~ /Y/) { # service is not started, and we want to send an event for this
							
								my $datestring = &getdatestring();
								my @args = ($svhash{sft_elmnt_id},undef,"WARNING!! The Service:  $svhash{service_name} is NOT RUNNING.",undef,'Service Not Running',$svhash{service_name},$datestring,undef,undef,$host);
								eval{$client->call('errorinsert',@args)};
								if ($@) {
									$lh->log_print("ERROR: Could not report event! :\t $@  Attempting to Reconnect")
									
										&startfrontier;
										#try again to connect...
										eval{$client->call('errorinsert',@args)};

									
									}

							}

						}
	}
}


sub senderrortovcs {
		my $sft_elmnt_id = shift;
		my $server = shift;
		my $event_string = shift;
		my $usr_event_level = shift;
		my $usr_event_type = shift;
		my $usr_event_sub_type = shift;
		my $event_time = shift;
		my $error_defs_id = shift;
		my $cc_alias = shift;
		my $host = shift;
		my $analysis_rule_id = shift;

		#args = my ($sft_elmnt_id,$server,$event_string,$usr_event_level,$usr_event_type,$usr_event_sub_type,$event_time,$error_defs_id,$cc_alias,$host,$analysis_rule_id) =@_;
	
		my @args = ($sft_elmnt_id,$server,$event_string,$usr_event_level,$usr_event_type,$usr_event_sub_type,$event_time,$error_defs_id,$cc_alias,$host,$analysis_rule_id);
			eval{$client->call('errorinsert',@args)};
					if ($@) {
							$lh->log_print("ERROR: Could not report event! :\t $@ Attempting to Reconnect");
								&startfrontier;
								#try again to connect...
								eval{$client->call('errorinsert',@args)};
									#do nothing if it fails again
					}
						
}


#########################################################################
sub getdatestring {
		my $datestring;
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
				localtime(time);

#	if ($db = 'MSSQL') {
		#01/01/1998 23:59:15
		$year = $year + 1900;
		$mon = $mon + 1;
		$datestring = "$mon/$mday/$year $hour:$min:$sec";		
#	}

	return $datestring;
}


sub convert_to_seconds {
	my ($hours,$mins,$secs,$milsecs) = @_;

	$milsecs = "." . $milsecs; #gotta love perl...automagically understands what i'm saying here
	print "MILSECS = $milsecs\n";
	$secs += $milsecs;

    $secs += $mins * 60;
	$secs += $hours * 3600;
	return $secs;
}


sub checkerror {
	my %ehash = @_;
	 if ($ehash{ERROR}) {
		 $lh->log_print($ehash{ERROR});
		 return 1;}
	}



