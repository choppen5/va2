#!d:\perl\bin\perl  

use strict;
use vadmin::vconfig;
use vadmin::data1;
use Log::Logger;

use vadmin::srvrmgr;
use Win32::Service;
use Win32;

use Win32::API;  #added 10/27/2007 
use Getopt::Long;

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



my $db = 'MSSQL';

my $lh = new Log::Logger "$rootpath/log/vsrvrmgr".$siebsrvr.".log" || new Log::Logger "./vsrvrmgr".$siebsrvr.".log"  ;				# global log file
$lh->log_print("Start up.......");             # first log comment

my $instid = ($ARGV[2] || 1); # CO 9/3/2007 - changed to take no required parameters # $lh->fail("Command line args incorrect - use: vsrvrmgr.exe siebsrvrname instid");  # shift in the siebel server

## added 10/27/2007  for process collection
# Define some contants
my $DWORD_SIZE = 4;
my $PROC_ARRAY_SIZE = 100;
my $MODULE_LIST_SIZE = 200;

my $nopsapi; #true if we can not load psapi.dll
my $usepsapi; #check if we are using psapi..

# Define some Win32 API constants
my $PROCESS_QUERY_INFORMATION = 0x0400;
my $PROCESS_VM_READ = 0x0010;
my $OpenProcess = new Win32::API( 'kernel32.dll', 'OpenProcess', ['N','I','N'], 'N' ) || $lh->log_print("Can not openprocess");
my $CloseHandle = new Win32::API( 'kernel32.dll', 'CloseHandle', ['N'], 'I' ) || $lh->log_print("Can not openprocess");
my $GetProcessMemoryInfo = new Win32::API( 'psapi.dll', 'GetProcessMemoryInfo', ['N','P','N'], 'I' ) || ($lh->log_print("Can not link GetProcessMemoryInfo()") and $nopsapi = 1);
my $EnumProcesses = new Win32::API( 'psapi.dll', 'EnumProcesses', ['P','N','P'], 'I' ) || ($lh->log_print("Can not link EnumProcesses") and $nopsapi = 1);

my $EnumProcessModules = new Win32::API( 'psapi.dll', 'EnumProcessModules', ['N','P','N','P'], 'I' ) || ($lh->log_print("Can not link EnumProcessModules") and $nopsapi = 1);
my $GetModuleBaseName = new Win32::API( 'psapi.dll', 'GetModuleBaseName', ['N','N','P','N'], 'N' ) || ($lh->log_print("Can not link GetModuleBaseName")and $nopsapi = 1 );
my $GetProcessTimes = new Win32::API('kernel32', 'GetProcessTimes',['I','P','P','P','P'], 'I') || ($lh->log_print("Can not link GetProcessTimes ") and $nopsapi = 1);




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


## added 10/27/2007 -  checking for psapi.dll
if (!$nopsapi) {
	$usepsapi = 1;
} else {
	$usepsapi = 0;
	$lh->log_print("WARNING!! No psapi.dll installed on system. Advise downloading from Microsft for improved performance.");
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
	
	my @allrunning = (); 

	if ($debug) {$lh->log_print("Gathering PID info from OS")}	
	@allrunning  = &printprocesses();
	if ($debug) {$lh->log_print("FINISHED getting OS PID info.")}	

	foreach $pid (@pids) {  #cycle through the pids from the db
		if ($debug) {$lh->log_print("pid = $pid")}

		
		$pidrun = grep(/\b$pid\b/,@allrunning );   #look for db pid in the currently running pids list 
		unless ($pidrun) {                     #if not found, delete db pid
			$lh->log_print("Cleaned up PID $pid, no longer running.");
			&vadmin::data1::deletepidbypid($datasession,$debug,$lh,$pid,$host);
		}
	}
	if ($debug) {$lh->log_print("FINISHED ALL PID PROCESSING")}	
}



sub printprocesses {

	my (@EnumInfo,$i,$Info);	
	my @running;
	my $update;
	my $noupdate;
		
	my $obj;		#used if we have to use IProc		
	my @EnumInfo;	#list of pids


	if ($usepsapi) {
		@EnumInfo = GetPidList();
	} else {
		$obj=new Win32::IProcess || $lh->log_print("Can not create an IProcess object.."); 
		$obj->EnumProcesses(\@EnumInfo);
	}

	my $numprocs = scalar(@EnumInfo);

	

	if ($debug ) {$lh->log_print("Number of processes returned (excludes System Idle Process 0 and system process 4) = $numprocs")};

	#change the for loop to only expect a pid


	for($i=0;$i<$numprocs;$i++)
		{
			
			my $Hnd;
			my $TimeInfo;
			#initialize variables
			my $procname;
			my $pid;
			my $cputime; #combine cpu user and kerenel time
			my $usersecs;
			my $kernelsecs;
			my $creationtime;
			my $pagefaults;
			my $workingset; #physical memory
			my $pagefile; #virgual memory
			my %procmem;


			my %Proc; #hash that holds the variables for process information
			#we are either useing psapi or not, set the variable names.  some systems such as NT 4.0 and 2000 don't necesarilly have psapi installed.  Unfortunately, then we have to use iproc.pm which has filehandle in pagefault leaks.

			if ($usepsapi) {
				
				$pid = $EnumInfo[$i];
				# do not gather information about pid 0 (system idle) or 4 (system) processes
				if ($pid==0 || $pid==4) {
					next;
				}


				%Proc = &GetProcessInfo($pid);
				$pagefaults = $Proc{workingsetpeak};
				$workingset = $Proc{workingset} /1024;
				$pagefile = $Proc{pagefileuse}/ 1024;
				$procname = $Proc{name};
				$kernelsecs = $Proc{kerneltime};
				$usersecs =	$Proc{usertime};
				$cputime = $usersecs + $kernelsecs;

			} else {
				
				if ($debug) {"Warning, using iproc.dll not psapi.dll! Advise installing psapi.dll\n"};
				
				$obj->Open($EnumInfo[$i]->{ProcessId},PROCESS_QUERY_INFORMATION | PROCESS_VM_READ,INHERITED,\$Hnd); 
				$obj->GetStatus($Hnd,\$TimeInfo,DIGITAL);
				#call the GetProcessMeminfo - unfortunately this has a handle leak, but use it where there is no psapi dll
				$obj->GetProcessMemInfo($EnumInfo[$i]->{ProcessId},\$Info);

				#added to close handles
				$obj->CloseHandle($Hnd);
				
				

				$pid = $EnumInfo[$i]->{ProcessId};
				$procname = $EnumInfo[$i]->{ProcessName};

				$pagefaults = $Info->{PageFaultCount};
				$workingset = $Info->{WorkingSetSize}/1024;
				$pagefile= $Info->{PagefileUsage}/1024;

				my @usertime = split(":",$TimeInfo->{UserTime});
				$usersecs = convert_to_seconds($usertime[0],$usertime[1],$usertime[2],$usertime[3]);
				my  @kerneltime = split(":",$TimeInfo->{KernelTime});
				$kernelsecs = convert_to_seconds($kerneltime[0],$kerneltime[1],$kerneltime[2],$kerneltime[3]);
				$cputime = $usersecs + $kernelsecs;
				
			}
						
			
			
			if ($debug ) {$lh->log_print("Proc Name = $procname  Process Id = $pid. User seconds = $usersecs. Kernel Seconds = $kernelsecs. CPU Time = $cputime pagefaults = $pagefaults workingset =$workingset pagefile= $pagefile")};



			push @running,$pid;  #will return @running                             
			my %running;
					
							
			$running{$pid} = [$pid,$procname,undef,$cputime,$kernelsecs,$usersecs,$workingset,$pagefaults,$pagefile,undef,undef];

			
			
			if ($taskreset) {
				#&vadmin::data1::updatepid($datasession, $debug, $lh,$host,@{$running{$pid}});	
			}	
			

			if (%prevrunning) 
			{  #will be untrue on first run
						if ($pidcompare->compare(\@{$running{$pid}},\@{$prevrunning{$pid}})) {
							if ($debug) {$lh->log_print("MATCHES ARRAY - DO NOT UPDATE $pid")};	
							$noupdate++;
						} 
						else 
						{ # does not match, insert record   
							if ($debug) {$lh->log_print("NO MATCH ARRAY - UPDATE $pid ")};
							#print "PREVOUS ARRAY = @{$prevrunning{$pid}\n";
							#print "NEW ARRAY = @{$running{$pid}}\n";
							$update++;
							&vadmin::data1::updatepid($datasession, $debug, $lh,$host,@{$running{$pid}});	
						}		 			
			} 
			else 
			 { #no previous hash, insert everything
					if ($debug) {$lh->log_print("NO PREVIOUS ARRAY -UPDATE $pid ")};
					&vadmin::data1::updatepid($datasession, $debug, $lh,$host,@{$running{$pid}});	
			 }
						

			if (%prevrunning) {delete $prevrunning{$pid}}
					$prevrunning{$pid} = [$pid,$procname,undef,$cputime,$kernelsecs,$usersecs,$workingset,$pagefaults,$pagefile,undef,undef];
					%running = undef;

			if ($debug) {$lh->log_print("Process updates = $update Process noupdates = $noupdate")}; 

		} # end enum processes

		$obj = undef;
		(@EnumInfo,$i,$Info) = undef;
	
	return @running;

}


sub GetProcessInfo()
{
    my( $Pid ) = shift;
	
    my( %ProcInfo );

    $ProcInfo{name} = "unknown";
    $ProcInfo{pid}  = $Pid;

    my( $hProcess ) = $OpenProcess->Call( $PROCESS_QUERY_INFORMATION | $PROCESS_VM_READ, 0, $Pid );
    if( $hProcess)
    {
        my( $BufferSize ) = $MODULE_LIST_SIZE * $DWORD_SIZE;
        my( $MemStruct ) = MakeBuffer( $BufferSize );
        my( $iReturned ) = MakeBuffer( $BufferSize );      
		
     
        if( $EnumProcessModules->Call( $hProcess, $MemStruct, $BufferSize, $iReturned ) )
        {
            my( $StringSize ) = 255 * ( ( Win32::API::IsUnicode() )? 2 : 1 );
            my( $ModuleName ) = MakeBuffer( $StringSize );
            my( @ModuleList ) = unpack( "L*", $MemStruct );
            my $hModule = $ModuleList[0];
            my $TotalChars;

            # Like EnumProcesses() divide $Returned by the # of bytes in an HMODULE
            # (which is the same as a DWORD)
            # and that is the number of module handles returned.
            # In this case we only want 1; the first returned in the array is
            # always the module of the process (typically an executable).
            $iReturned = unpack( "L", $iReturned ) / $DWORD_SIZE;

            if( $TotalChars = $GetModuleBaseName->Call( $hProcess, $hModule, $ModuleName, $StringSize ) )
            {
                $ProcInfo{name} = FixString( $ModuleName );
            }
            else
            {
                $ProcInfo{name} = "unknown";
            }
		}		
		
		my $BufSize = 10 * $DWORD_SIZE;
        $MemStruct = pack( "L10", ( $BufSize, split( "", 0 x 9 ) ) );

		
		if( $GetProcessMemoryInfo->Call( $hProcess, $MemStruct, $BufSize ) )
        {
          my( @MemStats ) = unpack( "L10", $MemStruct );
          $ProcInfo{workingsetpeak} = $MemStats[2];
          $ProcInfo{workingset} = $MemStats[3];
          $ProcInfo{pagefileuse} = $MemStats[8];
          $ProcInfo{pagefileusepeak} = $MemStats[9];
			
		
		}

		#now get cpu info

		$GetProcessTimes = new Win32::API('kernel32', 'GetProcessTimes',[qw(I P P P P)], 'I') or print'Failed to get GetProcessTimes: ', Win32::FormatMessage (Win32::GetLastError ());

		my $lpCreationTime = pack 'I2', 0, 0;   # 100ns since 1/1/1601
		my $lpExitTime = pack 'I2', 0, 0;
		my $lpKernelTime = pack 'I2', 0, 0;
		my $lpUserTime = pack 'I2', 0, 0;
 
		my $ret = $GetProcessTimes->Call($hProcess, $lpCreationTime, $lpExitTime,$lpKernelTime, $lpUserTime) or print  "Call GetProcessTimes: ",Win32::FormatMessage (Win32::GetLastError ());
		
		my @kerneltime = reverse unpack 'I2', $lpKernelTime;
		my @usertime  =  reverse unpack 'I2', $lpUserTime;
		
		$ProcInfo{kerneltime} = $kerneltime[1] / 10000000;
		$ProcInfo{usertime} = $usertime[1] / 10000000;

        $CloseHandle->Call( $hProcess );
    } else {
		  
        print Win32::FormatMessage (Win32::GetLastError ());  
		print "Could not open $Pid.. trying to force open\n";
		
		ForceOpen($Pid);

	}


    return( %ProcInfo );
}


sub GetPidList()
{
	
    my( @PidList );
    my $ProcArrayLength = $PROC_ARRAY_SIZE;
    my $iIterationCount = 0;
    my $ProcNum;
    my $pProcArray;

    do
    {
        my $ProcArrayByteSize;
        my $pProcNum = MakeBuffer( $DWORD_SIZE );
        #print "Reset the number of processes since we later use it to test\n";
        # if we worked or not
        $ProcNum = 0;
        $ProcArrayLength = $PROC_ARRAY_SIZE * ++$iIterationCount;
        $ProcArrayByteSize = $ProcArrayLength * $DWORD_SIZE;
        # Create a buffer
        $pProcArray = MakeBuffer( $ProcArrayByteSize );
		#print "about to call enumprocesses\n";
        if( 0 != $EnumProcesses->Call( $pProcArray, $ProcArrayByteSize, $pProcNum ) )
        {
            # Get the number of bytes used in the array
            # Check this out -- divide by the number of bytes in a DWORD
            # and we have the number of processes returned!
            $ProcNum = unpack( "L", $pProcNum ) / $DWORD_SIZE;
            #print "Total procs: $ProcNum\n";
        }
    } while( $ProcNum >= $ProcArrayLength );

   if( 0 != $ProcNum )
    {
        # Let's play with each PID
        # First we must unpack each PID from the returned array
        @PidList = unpack( "L$ProcNum", $pProcArray );
    }
	
    return( @PidList );
}


sub ForceOpen
{
    
	my $TOKEN_QUERY                = 0x0008;
    my $TOKEN_ADJUST_PRIVILEGES    = 0x0020;
    my $SE_PRIVILEGE_ENABLED       = 0x02;
    my $PROCESS_TERMINATE          = 0x0001;
	my $PROCESS_ALL_ACCESS = 0x1F0FFF;
    my $SE_DEBUG_NAME              = "SeDebugPrivilege";

    my $GetCurrentProcess = new Win32::API( 'Kernel32.dll', 'GetCurrentProcess', [], 'N' ) || die;
    my $OpenProcessToken = new Win32::API( 'AdvApi32.dll', 'OpenProcessToken', ['N','N','P'], 'I' ) || die;
    my $LookupPrivilegeValue = new Win32::API( 'AdvApi32.dll', 'LookupPrivilegeValue', ['P','P','P'], 'I' ) || die;
    my $AdjustTokenPrivileges = new Win32::API( 'AdvApi32.dll', 'AdjustTokenPrivileges', ['N','I','P','N','P','P'], 'I' ) || die;
    my $TerminateProcess = new Win32::API( 'Kernel32.dll', 'TerminateProcess', ['N','I'], 'I' ) || die;

	
	my( $Pid ) = @_;
    my $iResult = 0;
    my $phToken = pack( "L", 0 );
    if( $OpenProcessToken->Call( $GetCurrentProcess->Call(), $TOKEN_ADJUST_PRIVILEGES | $TOKEN_QUERY, $phToken ) )
    {
        my $hToken = unpack( "L", $phToken );
        if( SetPrivilege( $hToken, $SE_DEBUG_NAME, 1 ) )
        {
            my $hProcess = $OpenProcess->Call( $PROCESS_ALL_ACCESS  , 0, $Pid );
            if( $hProcess )
            {
                SetPrivilege( $hToken, $SE_DEBUG_NAME, 0 );
                print "forced open pid $Pid\n";
				$CloseHandle->Call( $hProcess );

			} else {
				  print "could not force $Pid.. ". Win32::FormatMessage (Win32::GetLastError ());  ;
			}
				     
        } # end if set privelatge    
		$CloseHandle->Call( $hToken );
     }
        
}   



sub MakeBuffer
{
    my( $BufferSize ) = @_;
    return( "\x00"  x $BufferSize );
}

sub FixString
{
    my( $String ) = @_;
    $String =~ s/(.)\x00/$1/g if( Win32::API::IsUnicode() );
    return( unpack( "A*", $String ) );
}

sub FormatNumber
{
    my( $Number ) = @_;
    while ($Number =~ s/^(-?\d+)(\d{3})/$1,$2/){};
    return( $Number );
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



