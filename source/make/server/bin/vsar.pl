#!/usr/bin/perl

use vadmin::vconfig;
use vadmin::data1;
use strict;
use Log::Logger;
use Win32;
use IO::Socket;
use IO::Select;
use Win32::Process;
use Frontier::Client;
use Net::Ping;
use vadmin::DataException;
use Error qw(:try);
use vadmin::resonateagentrules;

use vars qw(%hup $datasession);

%main::hup;    #hash of user preferneces
$main::datasession;



my $host = Win32::NodeName;

use Cwd 'abs_path';	    # aka realpath()
my $rootpath = abs_path("..");


my (  $key, %srvmgrvars );


print "Log Path = $rootpath\\log\\\n";

my $lh = new Log::Logger "$rootpath\\log\\vsar.log" || new Log::Logger "vsar.log";    # global log file

$lh->log_print("HOST = $host");
$lh->log_print("Start up.......");          # first log comment


if ( checkerror( %hup = vadmin::vconfig::openlog() ) ) {  
    die;  # create user preference hash or die
} 
 
my $debug = $hup{DEBUG};

$lh->log_print("Data Session initializing.......");



try {
	$datasession = vadmin::data1::odbcsess($debug,$lh, $hup{VODBC}, $hup{USERNAME}, $hup{PASSWORD} );
	return;
} catch ConnectionInitializationFailure with {

	$datasession =  vadmin::data1::waitfordb($debug,$lh,$datasession, $hup{VODBC}, $hup{USERNAME}, $hup{PASSWORD});
};


if ($hup{DBTYPE} =~ /ORACLE/) {
 vadmin::data1::alterdateformat($datasession,$debug,$lh);
}

$lh->log_print("Connecting to VCS server: http://$hup{CENTRALSERVER}:$hup{CCPORT}/RPC2");

my $url  = "http://$hup{CENTRALSERVER}:$hup{CCPORT}/RPC2";
my $client = Frontier::Client->new( url   => $url,
					debug => $debug,
				  );

################################
# Moudule specific global vars #
################################


#while (1) {
#	my $interval = &vadmin::data1::getinterval($datasession);
#	if ($debug) {$lh->log_print("interval = $interval")};
#	&getnex;
#	sleep($interval);
#
#}


#run statisticcollectors
#run analysis objects
#	-> lanch vevalrunner
#	-> get analysis scripts 
#		-> send tcp/ip message to vevalruner  
#		-> wait for return or timeout		(timeout while waiting)
#		-> kill vevalrunner on timeout -(report error) (analysis object?)
#       -> launch new vevalrunner
#       -> record statistics				(basic execution times)
#       

# soar tasks ->  listen on db or tcp/ip channel
# run analysis object in protected eval mode
# record response of $retval - insert error events if false
#

my $host = '127.0.0.1';
my $eport = 15505; #CHANGE this to get it from a config file/db
my $cserviceport = $hup{CCSERVICEPORT};

my $quit = 0;
$SIG{INT} = sub { $quit++ }; 
my ($runningevalpid,$evalrunnersocket, %outstandingreqs,$lastic,$interval);

unless ($hup{DONTUPDATEIP}) {
	&SetHostsIP(); #set hostname IP addresses on startup, unless DONTUPDATEIP is set
}

&startup; 

sub startup {
	
	$lh->log_print("Startup....Launching New Evalrunner");
	my $ccserversocket = IO::Socket::INET->new("$host:$cserviceport") or $lh->log_print("CENTRAL SERVICE SOCKET ERROR:  $@");

	if ($runningevalpid) {#this won't do anything the first time.... if startup is called again it might kill a hung evalruner
		&killpid($runningevalpid);
		$eport++;
		eval{print $ccserversocket "REMOVE: $runningevalpid\n"};  #send a remove message to the central service - we are killing it ourselves
		if ($@) {$lh->log_print("$@\could not send message to Central Servier Service.")} 
		
	}

	$runningevalpid = &spawnevalrunner("vevalrunner.exe", $eport)or $lh->fail("Could not start the evalrunner.exe, exiting");
		$lh->log_print("Sending EvalRunner PID: $runningevalpid to Central Server Service for tracking...\n");
		$ccserversocket = IO::Socket::INET->new("$host:$cserviceport") or $lh->log_print("CENTRAL SERVICE SOCKET ERROR:  $@");
		eval{print $ccserversocket "ADD: $runningevalpid\n"};
		  if ($@) {$lh->log_print("$@\could not send message to Central Servier Service.")} 
	
	
	sleep(10);
	$evalrunnersocket = IO::Socket::INET->new("$host:$eport") or $lh->log_print("EVALRUNNER SOCKET ERROR:  $@.  Waiting 90 Seconds to restart Eval Runner") && sleep(20);
	
}
#starup the evalrunner

#cleanup old resonate rules
vadmin::resonateagentrules::cleanup($datasession,$debug,$lh);


while (1) {

	my @aoc = vadmin::data1::getaoh($datasession,$debug,$lh,"select execution_interval \"execution_interval\", collector_id \"collector_id\", notimeout \"notimeout\" from collector where active = 'Y' and parent_collector_id is null");
	my @aoa;	#array of analysis_rule hashses
	@aoa = vadmin::data1::getaoh($datasession,$debug,$lh,"select execution_interval \"execution_interval\",analysis_rule_id \"analysis_rule_id\", notimeout \"notimeout\" from analysis_rule where active = 'Y'");

	my $i;
	my $href;

	for ($i=10080;$i > 0 ;$i--) {
				#check hosts
				my @hosts;
				@hosts = vadmin::data1::gethosts($datasession,$debug,$lh);
				&pinghosts(@hosts);
				#fill up resonate rules 
				vadmin::resonateagentrules::runmain($datasession,$debug,$lh);
				my $interval = 60; #
				my $ttime = Win32::GetTickCount() ;
			############################################################
			#Cycle through the collector rules
			############################################################
					my $matchedintervals;
					my $stime = Win32::GetTickCount() ;
					
					#get system message - means that the statistics have been updated, so refresh the hash
					my %systemrec = vadmin::data1::gethashrecord($datasession,$debug,$lh,"select * from system_msg where type = 'STATUPD'");

						if (%systemrec) { #this means that there has been a change to the collectors, refresh the hash
								@aoc = vadmin::data1::getaoh($datasession,$debug,$lh,"select execution_interval \"execution_interval\", collector_id \"collector_id\", notimeout \"notimeout\" from collector where active = 'Y' and parent_collector_id is null");
								vadmin::data1::gethashrecord($datasession,$debug,$lh,"delete from system_msg where type = 'STATUPD'"); #remove the update record
						}

					for $href (@aoc) {
								my %newhash;
								%newhash = %$href;									#pass derefrenced hash to process event sub
								my $execution_interval = $newhash{'execution_interval'} || 1; #if there is no execution interval, defalut to 1 min

								if ( $i % $execution_interval  == 0) { #if the remainder of interval % execution_interval == 0 then we have a matching interval 		
									&runstatrules(%newhash);
									$matchedintervals++;
								}
					}
					
						my $etime = Win32::GetTickCount() ;
						if ($debug) {$lh->log_print("Execution Seconds for $matchedintervals Collectors: " .(($etime - $stime) / 1000))};
						if ($debug) {$lh->log_print("During interval: $i,  Execution Seconds for $matchedintervals Collectors: " .(($etime - $stime) / 1000))};
					
			############################################################
			#Cycle through the stat rules
			############################################################
					
					#reset vars instead of declaring new ones 
					$matchedintervals = 0;				
					$stime = Win32::GetTickCount() ;	
					
					%systemrec = vadmin::data1::gethashrecord($datasession,$debug,$lh,"select * from system_msg where type = 'ARULEUPD'");

						if (%systemrec) { #this means that there has been a change to the collectors, refresh the hash
							
								@aoa = vadmin::data1::getaoh($datasession,$debug,$lh,"select execution_interval \"execution_interval\",analysis_rule_id \"analysis_rule_id\", notimeout \"notimeout\"  from analysis_rule where active = 'Y'");
								vadmin::data1::gethashrecord($datasession,$debug,$lh,"delete from system_msg where type = 'ARULEUPD'"); #remove the update record

						}

					for $href (@aoa) {
								my %newhash;
								%newhash = %$href;									#pass derefrenced hash to process event sub
								my $execution_interval = $newhash{'execution_interval'} || 1; #if there is no execution interval, defalut to 1 min

								if ( $i % $execution_interval  == 0) { #if the remainder of interval / execution_interval == 0 then we have a matching interval 		
									&runarules(%newhash);
									$matchedintervals++;
								}

					}
					
						 $etime = Win32::GetTickCount() ;
						if ($debug) {$lh->log_print("During interval: $i,  Execution Seconds for $matchedintervals Analysis Rules: " .(($etime - $stime) / 1000))};
						
			############################################################
			#finished cycles
			############################################################

						my $latency = ($etime - $ttime) / 1000;
						
						if ($debug) {$lh->log_print("Total Execution time for Statistics and Analysis Rules during interval: $i,  Execution Seconds for $matchedintervals Analysis Rules: " .(($etime - $ttime) / 1000))};
						
						
						if ($latency < 60){						#adjustst to sleep less to syncronize statistic execution  time
							$interval = $interval - $latency
						} else {
							$lh->log_print("WARNING: The combination of Satistic and Analysis rules are taking longer than 60 seconds to execute.  This will result in a time frame creep for execution cycles\n") 	
							#we will sleep 60 seconds anyway
							#raise a error event?
						}

						print "latency = $latency\ninterval = $interval\n ";
						$interval = sprintf("%.0f",$interval);
						print "rounded interval = $interval";#insert cycle information here....

					sleep($interval);  
	} # we have cycled through 10800 intervals... 1 week in minutes

	
}



sub runstatrules {

	my $i;								#my $sql = "select * from collector where active = 'Y'";
	my %collectordef = @_;							#my @aobjarrays = vadmin::data1::getaoh($datasession,$debug,$lh,$sql);
	my $retval;
	
	  $retval = $collectordef{collector_id};
	  print "COLLECTOR RULE: $retval\n";
	  my $timeout =  $collectordef{notimeout};

	  print "NOTIMEOUT parameter for COLLECTOR = $timeout\n";
	
	  if ($timeout =~ /Y/) {
		  
		  if ($debug) {$lh->log_print("RUNNING A NO TIMEOUT RULE FOR COLLECTOR ID = $retval\n")};

		#launch a evalrunner and pass in paramaters (port notime type ruleid
		my $params = "$eport 1 \"COLLECTOR RULE\" $retval";
		&spawnevalrunner("vevalrunner.", $params);
		return 1;

	  } else {
	   
							  eval{print $evalrunnersocket "COLLECTOR RULE: $retval\n"}; #send message to the socket - picked up by the evalrunner on the other end of socket
								  if ($@) {$lh->log_print("$@\the socket must be dead, because the filehandle is invalid.  Restart the eval runner.");
								  &startup; #try startup again...maybe it will work this time
								  return 0;
								  } 
								  else {
							
									my $timeout;
									my $sel2 = new IO::Select( $evalrunnersocket );			 
									until ($sel2->can_read(1)) {
										print("can't read from socket reply - COLLECTOR ID: $retval");
										$timeout++;
										if ($timeout > 10) {

											my $timeoutmsg = "ERROR: STATISTIC $retval caused executor to fail... Restarting Evalrunner ";
											$lh->log_print($timeoutmsg);
						###############change/add new function	
										
										vadmin::data1::updatestaterr($datasession,$debug,$lh,$retval,"WARNING: This Statistic Collector Rule timed out and was set to inactive.");
											
											my $datestring = &getdatestring;
											my @args = (undef,undef,"WARNING: STATISTIC ID: $retval INACTIVATED DUE TO TIMEOUT",undef,"TIMEOUT","COLLECTOR",$datestring,undef,undef,$_,undef);					
											eval{$client->call('errorinsert',@args)};
											if ($@) {$lh->log_print("ERROR: Could not report event! :\t $@")}
											
											
											&startup;
											#mark rule inactive with errorcode
											return 0;
										}
									}

									my $msg_in = <$evalrunnersocket>;
									if ($msg_in =~ /SUCESSREQ:/) {
										$msg_in =~ /: (\d+)/;
										if ($debug) {$lh->log_print("Successful Return of Request: $1")}
										#update statistic execution time
										
									} else {
										$lh->log_print("ERROR: Unexpected result from Statistic Execution - Restarting Evalrunner ");
										&startup;
									}

								  }#send tcp/ip message to executor

			return 1;

	  }#end no timeout check
		
}



sub runarules {
	my $i;								#my $sql = "select * from collector where active = 'Y'";
	my %aruledef = @_;							#my @aobjarrays = vadmin::data1::getaoh($datasession,$debug,$lh,$sql);
	my $retval;


	  $retval = $aruledef{analysis_rule_id};
	  print "ANALYSIS RULE: $retval\n";


	  my $timeout =  $aruledef{notimeout};
		print "notimeout param FOR ANALYSIS RULE =  $timeout\n";

	  if ($timeout =~ /Y/) {
		  
		  if ($debug) {$lh->log_print("RUNNING A NO TIMEOUT RULE FOR ANALYSIS RULE ID = $retval")};

		#launch a evalrunner and pass in paramaters (port notime type ruleid
		my $params = "$eport 1 'ANALYSIS' $retval";
		&spawnevalrunner("vevalrunner.exe", $params);

	  } else {


	
				  eval{print $evalrunnersocket "ANALYSIS: $retval\n"};
					  if ($@) {$lh->log_print("$@\the socket must be dead, because the filehandle is invalid.  Restart the eval runner.");
					  &startup; #try startup again...maybe it will work this time
					  return 0;
					  } 
					  else {

						my $timeout;
						my $sel2 = new IO::Select( $evalrunnersocket );			 
						until ($sel2->can_read(1)) {
							$lh->log_print("can't read from socket reply - Analysis Rule id: $retval");
							$timeout++;
							if ($timeout > 5) {
								$lh->log_print("ERROR: Analsys Rule $retval caused executor to fail...- Restarting Evalrunner");
								vadmin::data1::udateaoerr($datasession,$debug,$lh,$retval,"WARNING: This Analisis Rule timed out and was set to inactive.");


								my $datestring = &getdatestring;
								my @args = (undef,undef,"WARNING: ANALYSIS RULE ID: $retval INACTIVATED DUE TO TIMEOUT",undef,"TIMEOUT","ANALYSIS_RULE",$datestring,undef,undef,$_,undef);					
								eval{$client->call('errorinsert',@args)};
								if ($@) {$lh->log_print("ERROR: Could not report event! :\t $@")}
								

								&startup;
								#mark rule inactive with errorcode
								return 0;
							}
						}

						my $msg_in = <$evalrunnersocket>;
						print "Analysis Rule Return Message: $msg_in\n";
						if ($msg_in =~ /SUCESSREQ:/) {
							$msg_in =~ /: (\d+)/;
							if ($debug) {$lh->log_print("Successful Return of Request: $1")}
							#update statistic execution time
							
						} else {
							$lh->log_print("ERROR: Unexpected result from Analysis Execution - Restarting Evalrunner ");
							&startup;
						}

					  }#send tcp/ip message to executor

				return 1;

	  };
	  return 1;
}


#########################################################################
sub checkerror {
    my %ehash = @_;
    if ( $ehash{ERROR} ) {
        $lh->log_print( $ehash{ERROR} );
        return 1;
    }
}

#########################################################################
sub spawnevalrunner {
	my ($path,$args) = @_;
	my $handle;
	print "path ars =  $path\n $args\n";

	eval {
	Win32::Process::Create($handle,
							$path,
							" $args",
							0,
							#CREATE_NO_WINDOW,
							NORMAL_PRIORITY_CLASS,
							".") || die "$!";
		};


		if ($@) {
			$lh->log_print("ERROR STARTING PROC\n"); 
			return "ERROR";
		  }	  
		my $pid = $handle->GetProcessID();
		$lh->log_print("SPAWNED evalrunner : $path $pid");
		return $pid;
}

################################################################################33
 sub killpid {
	my $pid = shift;
	my $exitcode;
	Win32::Process::KillProcess($pid, $exitcode) || ErrorReport();
 }


 ####################################################################
#sup erroreport
###################################################################
 
 sub ErrorReport{
       $lh->log_print( Win32::GetLastError() );
 }

sub SetHostsIP {
	my @hosts =  vadmin::data1::gethosts($datasession,$debug,$lh,1); #get all hosts,not just the noping ones
	foreach  (@hosts) {
		my $addr;
		eval {
			$addr=inet_ntoa((gethostbyname($_))[4]);
		};
		
		if ($@) {
			$lh->log_print("Error updating hostname $_ ipaddress");
		} else {
			$lh->log_print("Updating HOST $_  with IPADDRESS = $addr");
			my $sql = "update host set ipaddress = '$addr' where hostname = '$_'";
			vadmin::data1::execsql($datasession,$debug,$lh,$sql);
		}
	}

}


sub pinghosts {
 my @hosts = @_;
 for (@hosts) {
	 print "hostname = $_\n";
	#did not work with perl 5.8...so removed the icmp my $p = Net::Ping->new("icmp"); 
	my $p = Net::Ping->new();
	 unless ($p->ping($_, 2)) {
					my $datestring = &getdatestring;
		 			my @args = (undef,undef,"WARNING: HOST $_ UNREACHABLE",undef,"HOST_UNREACHABLE","$_",$datestring,undef,undef,$_,undef);					
					$lh->log_print("WARNING: Host $_ Unreachable");
					eval{$client->call('errorinsert',@args)};
					if ($@) {$lh->log_print("ERROR: Could not report event! :\t $@")}
	 }	
 }
}

sub getdatestring {
		my $datestring;
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
				localtime(time);
		$year = $year + 1900;
		$mon = $mon + 1;
		$datestring = "$mon/$mday/$year $hour:$min:$sec";		
	return $datestring;
}


sub holdingpattern {
	my $connectionproblem = 1;
		while ($connectionproblem) {
			$lh->log_print("HOLY MOTHER OF CHRIST!  WE'VE GOT A MAJOR DB CONNECTION FAILURE HERE... STANDBY...attempting to restore data connection\n");			
				#$datasession->Close();
				try {
					$datasession = vadmin::data1::odbcsess($debug,$lh, $hup{VODBC}, $hup{USERNAME}, $hup{PASSWORD} );
					$connectionproblem = 0;
					return;
				} catch ConnectionInitializationFailure with {
					$lh->log_print("CANNOT CONNECT... STANDBY FOR 90 SECONDS...");
					sleep(30);
				};
		}
	}



	sub evalsql {

		my $statement = shift;

        
		try {
			eval $statement;
		} catch ConnectionFailure with {

			 $datasession =  vadmin::data1::waitfordb($debug,$lh,$datasession, $hup{VODBC}, $hup{USERNAME}, $hup{PASSWORD});
			 eval $statement;	
		};




	}