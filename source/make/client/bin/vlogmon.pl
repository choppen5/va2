
use vadmin::vconfig;
use vadmin::data1;
use strict;
use Log::Logger;
use Win32::Service;
use Win32;
use Frontier::Client;
use Win32::OLE;

use Win32::OLE::Const 'DirWatcherATL 1.0 Type Library';


Win32::OLE->Option(Warn => 3 );




my $db = 'MSSQL';

Win32::OLE->Option(Warn => 3 );
# variables for use w/ in the script
my $dwError;
my $notificationType;
my $nNumNotificationsProcessed;
my $bExitOuterLoop; 
my $key;
my $nWaitResult;
my $watcher;

use vars qw(%hup $datasession);

my %srvmgrvars;

%main::hup;    #hash of user preferneces
$main::datasession;


 
my $host = Win32::NodeName;

use Cwd 'abs_path';	    # aka realpath()
my $rootpath = abs_path("..");


my $siebsrvr = $ARGV[0] || die("Command line args incorrect try: vlogmon.exe siebsrvrname"); ; # shift in the siebel server




print "Log path = $rootpath/log/vlogmon".$siebsrvr.".log" ;

my $lh = new Log::Logger "$rootpath/log/vlogmon".$siebsrvr.".log" || new Log::Logger "./vlogmon".$siebsrvr.".log" ;    # global log file

$lh->log_print("HOST = $host");
$lh->log_print("SIEBEL SERVER = $siebsrvr");


my $obj = Win32::OLE->new('DirWatcherATL.CATLDirectoryWatcher');

$lh->fail("Problem Loading DirWatcherATL: $@") unless $obj;


#########
#get command line siebsrvr
#########


$lh->log_print("Start up.......");          # first log comment


if ( checkerror( %hup = vadmin::vconfig::openlog() ) ) {  
    die;  # create user preference hash or die
} 



my $debug = $hup{DEBUG};
my $restartpause = $hup{RESTARTPAUSE} || 60; 
my $startpause = $hup{STARTPAUSE} || 0; 
my $lang = $hup{LANG};

if ($debug) {
	foreach $key (keys %hup) {
	$lh->log_print("hup $key = $hup{$key}"); 
	}
}


$datasession = vadmin::data1::odbcsess($debug,$lh, $hup{VODBC}, $hup{USERNAME}, $hup{PASSWORD} ); 
 

$lh->log_print("Data Session initialized.......");

checkerror( %srvmgrvars =
    vadmin::data1::getinitvars($datasession,$debug, $lh,$siebsrvr) );

if ($debug) {
	foreach $key (keys %srvmgrvars) {
		$lh->log_print ("srvmgrvars $key = $srvmgrvars{$key}");
	}
}

my $appserver_id = $srvmgrvars{'appserver_id'};

$lh->log_print("Appserver id = $appserver_id");


#shut down if the servername is not in the databse
unless ($srvmgrvars{server_name}) {$lh->fail("The provided Siebel Server \"$siebsrvr\" is not properly configured in the Vadmin Database, or is the wrong name.  Shutting down.")}


################################
# Moudule specific global vars #
################################

my $server_id = $srvmgrvars{server_id};

my ( %files, @comps, $numlines, $thread1, $thread2, $pause );
my ( $i,     @data );
my ( $running, $notrunning, %status );
my $WatchDir;
my $wait;
my $FileList;

my %comperr;



my $server  = ("\\\\$host");
my $service = ("siebsrvr_". $srvmgrvars{enterprise}."_".$srvmgrvars{server_name});
my $check   = ("CurrentState");
#Added 3/23/2009
my $logdir = $srvmgrvars{"logdir"};

$lh->log_print("Server = $server");
$lh->log_print("Searching for Siebel Service: $service.  If this Service is not running this process will fail.");
$lh->log_print("Log dir = $logdir");

#use config info to get ipaddress and port
my $url  = "http://$hup{CENTRALSERVER}:$hup{CCPORT}/RPC2";
my $client = Frontier::Client->new( url   => $url,
					debug => $debug,
				  );

my $restartthread = 0; #set when service is restarted

if ($startpause) {

	$lh->log_print("Starting the vlogmon service - pausing $startpause seconds on startup due to STARTPAUSE parameter being set in config db");

	sleep($startpause);

}


&svcheckblock; #block until service is up 
&mainmonitor;

sub svcheckblock { # blocks until service is running
    my $prevnotrunning;
	my $updatemsg;
	my $notrunning = 1;
	while ($notrunning) {
		Win32::Service::GetStatus($server, $service, \%status);
		if ($status{$check} == 4){
			$lh->log_print("The Service is UP - starting the Log Monitoring Session");
				updatesrvrstatus($datasession,$debug,$lh,$appserver_id,"RUNNING");
			
				if ($prevnotrunning ) {

					$lh->log_print("Siebel Server has been Restarted - waiting $restartpause seconds before starting new session");
					
					sleep($restartpause);
				}#the service just started, give it a while to get up
			$notrunning = 0;					 #this will exit the while
		}else {
			unless ($updatemsg) {
										$lh->log_print("Waiting for Service to Start......");
										updatesrvrstatus($datasession,$debug,$lh,$appserver_id,"STOPPED");
										$prevnotrunning =1;  
										sleep(1);

										#update server status	
										$updatemsg = 1;
									}
			#adjust global running variables - print something 1 time to log file indicating waiting
			print "The Service is not currently running\n"};
			sleep(1);
			
			
	}	
}



sub mainmonitor { #this sub will be called by side monitor, once Siebel server is running

#	$obj = new Win32::AdvNotify || die "Can not create an AdvNotify object\n";
	&startthread1;
	#&startthread2;

	sub startthread1 {

								

	my $comp;
			@comps = getcompsmonitored( $datasession,$debug, $lh,$server_id );
				foreach $comp (@comps) {
					#print "COMP = $comp\n";
					my @errors = &vadmin::data1::getstringerrors(  $datasession, $debug, $lh, $comp,$server_id );
	
				$comperr{$comp} = [@errors];
				}
				
			
			#print functions
					foreach (@comps) {
						if  ($debug) {$lh->log_print("Component being monitored = $_")}
					}

			#should check to see if siebel server is running before geting numlines
			$numlines =
			  &getloglines(
				"$logdir$srvmgrvars{enterprise}.$srvmgrvars{server_name}.log");
			
			#clean up previous pids if any
			#CO changed 11/2/2007 - removed logmon cleanup of pids. expected that vsrvrmgr process managment will handle this
			#vadmin::data1::deletepidbyid($datasession,$debug,$lh,$appserver_id);
			

			&createfilehash(); #create initial hash of files to monitor and their size - used for already started files
			
			foreach $key (keys %files) {
				if ($debug) {$lh->log_print("MONITORING $key WITH $files{$key} BYTES")};
			}

			
			&parsefrmfstline("$logdir$srvmgrvars{enterprise}.$srvmgrvars{server_name}.log");

			open (FH,"$logdir\\$srvmgrvars{enterprise}.$srvmgrvars{server_name}.log") or $lh->log_print("dead $!");#
			#open (FH,'C:\charles\recursive\prospects\canal+\SIEBPPRD2.SIEBPPRD100.log') or $lh->log_print("dead $!");#
			


			while (<FH>) {
			processpids($_,1);
				}

			close FH;

			$lh->log_print("$logdir");
			$lh->log_print("thread1 startING");
			#	$thread1 = $obj->StartThread(
			#		Directory    => "$logdir",
			#		Filter       => FILE_NAME | SIZE | SECURITY,
			#		WatchSubtree => Yes
			#) || die $lh->fail("Can't start thread1..path specified in config db:$srvmgrvars{serverpath} must be wrong. \n");

	
			 $obj->{FilterFlags} = (dwWatchedDirectoryNotLocked | dwCheckFullPath);


			eval {			
			$dwError = $obj->WatchDirectory("$logdir", # szDirToWatch
                         	    8 | 2 | 1 | 3, # dwChangesToWatchFor
                         	    1 ,         # bWatchSubDirs     
								"$logdir*", #filter
								""
                         	    );
			};
			
			if ($dwError) {$lh->fail("The directory couldn't be watched! ErrorCode: $dwError $logdir $@")}

			eval {			
			$dwError = $obj->WatchDirectory("$rootpath\\msg\\", # szDirToWatch
                         	    8 | 2 | 1 | 3, # dwChangesToWatchFor
                         	    1 ,         # bWatchSubDirs     
								"$rootpath\\msg\\*", #filter
								""
                         	    );
			};

			if ($dwError) {$lh->fail("The directory couldn't be watched! ErrorCode: $dwError $rootpath\\msg\\ $@")}

			#$lh->fail("The directory couldn't be watched! ErrorCode: " . $dwError . "\n") unless $dwError == 0;
			
  	}
	

	


	my $wait;
	while ($nWaitResult = $obj->WaitForNotification(-1)) {

	  if( $nWaitResult == 0 )
	   {
		print "Wait Cancelled, or timed out...\n";
		$bExitOuterLoop = 1;
	   }
	   else
		{

		 do{					
					
			print "file changed: $obj->{'FileName'} \n";			
			print "notification type = $obj->{'NotificationType'}\n";

			if ($obj->{FileName} =~ /msgfile.txt/) {
						#$lh->log_print ("RECIEVED A RESTART MESSAGE.  RESTARTING THREAD FOR COMPONENT MONITORING. \n\n");
						$lh->log_print ("RECIEVED A RESTART MESSAGE.  MUST RESTART LSM TO MONITOR FOR ERROR\n");
						#$obj->UnWatchAllDirectories();
						#&startthread1;
					}

			 if ($obj->{'FileDirectory'} =~ /siebsrvr/) {
				print "matched siebsrvr.... $obj->{'FileDirectory'}\n";
					
					if ( $obj->{'NotificationType'} == 3) {#"FILE_ACTION_ADDED"
						
						#we'll parse out the comp and PIDs every time a new file is added
						parsefrmfstline($obj->{'FileDirectory'} . $obj->{'FileName'});
						
						#antiquated start and stop system
						if ($obj->{'FileName'} =~ /$srvmgrvars{enterprise}.$srvmgrvars{server_name}.log/) {

							$lh->log_print("Begin monitoring $srvmgrvars{enterprise}.$srvmgrvars{server_name}.log - after server restart");

							$restartthread = 1;
							$pause = 0;
							$numlines = 0;
						}
						
					}

					print "about to check to see if the log file has been modfied..\n";

					

					if ($obj->{FileName} =~ /$srvmgrvars{enterprise}.$srvmgrvars{server_name}.log/ && ($pause != 1))#&& ($pause != 1)
					{
						print "SiebSrvr Log file change\n";
						#server.APPSERVER.log has changed, parse it;
						$wait = &parsefile( $obj->{'FileDirectory'} . $obj->{'FileName'}, $obj->{'FileName'});
						
						if ($wait == 0) {
							
							my ($updatemsg,$sdown);
							my $running = 1;
							while ($running) {

								Win32::Service::GetStatus($server, $service, \%status);
								if ($status{$check} == 4){
									print "The Service is UP..waiting for it to die\n";
									unless ($sdown) {
										$lh->log_print("Waiting for Service to Start......\n");
										updatesrvrstatus($datasession,$debug,$lh,$appserver_id,"SHUTTING DOWN");
										
										#update server status	
										$sdown = 1;
										}

								}else{ 
									print "The Service is DOWN..waiting for it to start\n";
									unless ($updatemsg) {
										$lh->log_print("Waiting for Service to Start......\n");
										updatesrvrstatus($datasession,$debug,$lh,$appserver_id,"STOPPED");
									
										#update server status	
										$updatemsg = 1;
									}
									$running = 0;
									$notrunning = 1;
								}
								sleep(1);
							}

							while ($notrunning) {
								Win32::Service::GetStatus($server, $service, \%status);
								if ($status{$check} == 4){
									print "The Service is Restarted and UP...Waiting 45 seconds\n";
									updatesrvrstatus($datasession,$debug,$lh,$appserver_id,"RUNNING");

									$lh->log_print("Siebel Server has been Restarted - waiting $restartpause seconds before starting new session");					
									sleep($restartpause);

									$restartthread = 0;
									$pause = 0;
									startthread1;
								
									$notrunning = 0;
								}else {
									print "The Service is DOWN..waiting for it to start\n"};
									sleep(1);
								}	


							#$thread1->Terminate();
								

						}
						
					
					
					} 
					elsif ($pause != 1) {
						print "elseif satisfied..\n";
						# CO - 9/3/2007  - split /\_/ not compatible with component names with underscores in it.
						# 9/3/2007 - changed it to use a . instead. Would not work with file names with multiple periods. Fine with Siebel though.
						#my @fl = split /\_/, $obj->{'FileName'};  #parse the type of component from log file name
						#9/4/2007 -  changed again!! the . was not good, did not take into consideration 
						my @fl = split /\_\d+\.log/, $obj->{'FileName'}; 
						
						
						if ( checkforcomp( $fl[0] ) ) {				
							
							print "about to parsecompfile...\n";
							#print  "COMP $fl[0] MATCHES....\n"; 
	
				
							my @stringerrors;
							#make sure $comperr{$fl[0]) isn't undefined
							if ($comperr{$fl[0]}) {
								 @stringerrors = @{$comperr{$fl[0]}} ;#was erroring here
							
    							&parsecompfile(							#parse the change
									$obj->{'FileDirectory'} . $obj->{'FileName'},
									$obj->{'FileName'}, $fl[0],@stringerrors );
							
							}

							
							
							
						}
						
					}
			   }		
			} until( !$obj->GetNextNotification() );
			# end siebsrvr section
	
		}


	}
	#print "\nThe signal is: " . $EventName{ $obj->{Event} } . "\n";

}
#############################################################################
#sub checkforcomp ($file) - component name, executes sql, and returns true if component name is monitored 
#############################################################################

sub checkforcomp {  
    my $file = shift;
	#@comps = getcompsmonitored( $datasession, $debug, $lh );
    foreach $key ( @comps ) {
		#print "comp = $key\n";
        if ( $key =~ /$file/ ) {
			print "file matched!\n";
            return 1;
        }
    }
    return 0;    #no match, got all the way through the hash
}
#############################################################################
#sub getloglines ($filepat) - returns lenght of file based on new lines
#############################################################################

sub getloglines {
    my $filepath = shift;
    my $count = (-s $filepath);
	
	  
    return $count;
}

#############################################################################
#sub parsefile ($filepath) - parses srvrmgr log files - increments $numlines if not paused
#############################################################################

sub parsefile {
    my $filepath = shift;
	my $key = shift;
    my $count;
	my $retval = 1;
    my @stringlist;
	#print "numlines = $numlines\n";

	my $test;
	my $size;

	if ($debug) {"PARSING FILE.  FILEPATH = $filepath"}
    open( FH, $filepath ) or $lh->log_print("PARSE FILE ERROR. Couldn't open $filepath");
    
	$test = seek (FH,$files{$key},1);

    
    while  (<FH>) {
       
            if ($debug) {$lh->log_print("$siebsrvr LOG FILE UPDATE: $_")}

            @stringlist = split ( /\t/, $_ );
           
			$retval = actonline($_,@stringlist);
			unless ($retval) {
				close FH;
				return $retval;
			}

			#print "INCREMENTING NUMLINES = $numlines\n";
        }

		$size = (-s $filepath);		  
        $files{$key} = $size;

    close FH or $lh->log_print("died closing $!");
	return $retval;
}


#############################################################################
#sub actonline (@line) - checks for server log messages, such as shut down, inserts data
#############################################################################

sub actonline {
    my $key;
	my $retval= 1;
	my $scline = shift;
    my @line = @_;
	

	if ($scline =~ /Shutting down due to service stop command/) {
		%files = undef;
		$numlines = 0;
		$pause = 1;
		$lh->log_print("Pausing Server monitoring due to a requested Siebel Server Shutdown");
		
		#CO changed 11/2/2007 - removed logmon cleanup of pids. expected that vsrvrmgr process managment will handle this
		#vadmin::data1::deletepidbyid($datasession,$debug,$lh,$appserver_id);

		$retval = 0;
		#delete server records?
		#pause
	}
	
	#insertappmsg($datasession,$debug,$lh,$srvmgrvars{servername},@line);
	processpids($scline);
	#print $scline;
	return $retval; 
}

##############################################################################################################
#sub parsecompfile ($filepath,$key,@errors) - genralized mechanism for recieving a hash that contains a 
#key = $filepath, and value = $linecount.  If $key doesn't exist it magically creates it for you, with linecount =0 (thanks perl!)
#Calls function finderrors if new lines are found, once per new line
#############################################################################################################

sub parsecompfile {
    my $filepath = shift;
    my $key      = shift;
    my $comp     = shift;
    my @errors   = @_;
    my $count;
    my @stringlist;
	my $test;
	my $size;

	if ($debug) {"PARSING COMPONENT FILE.  FILEPATH = $filepath"}

    open( FH, $filepath ) or $lh->log_print("couldnt open $filepath");
    
	$test = seek (FH,$files{$key},1);
	

	while (<FH>) {
		chomp $_;
		if ($debug) {$lh->log_print("COMP LINE = $_")}
            finderror( $_, $comp, $filepath, @errors );
      
    }

		$size = (-s $filepath);
		if ($debug) {$lh->log_print("file =  $filepath\nsize = $size ")}
				  
        $files{$key} = $size;
		
    close FH || $lh->log_print("died $!");
}

##############################################################################################################
#sub finderror ($line,@errors) - reads line and compares against error list, returns if "error" found
#############################################################################################################

sub finderror {
    my $error;
    my $line   = shift;
	my $comp = shift;
	my $filepath = shift;
	my ($matches,$total,$anded);
    my @errors = @_;
	my @stringlist = split ( /\t/, $line);
	
	chomp $line;
    for $error (0..$#errors) {
		
		
#		if ($errors[$error][5] =~ /Y/ ) { #if template = Y, must match all parts string
#			$anded = $errors[$error][6];
#
#			for $i (0..4) {
#				
#				if ($errors[$error][$i]) {
#					$total++;
#						
#						if ($stringlist[$i] =~ ($errors[$error][$i]) ) {
#							$matches++;
#		
#						}
#					}
#			}
#			
#			if ($anded == "Y" && $matches == $total) {
#								if (1) {$lh->log_print("TEMPLATE SEARCH WITH ANDED CONDITIONS FOR COMPONENT $comp:\tFOUND A MATCH: $line")};
#								#&inserterrorevent($datasession,$debug,$lh,$server_id,$srvmgrvars{server_name},$errors[$error][4],$errors[$error][7],$errors[$error][8],$errors[$error][9])
#								my @args = ($server_id,$srvmgrvars{server_name},$errors[$error][4],$errors[$error][7],$errors[$error][8],$errors[$error][9]);
#								eval{$client->call('errorinsert',@args)};
#								if ($@) {$lh->log_print("ERROR: Could not report event! :\t $@")}
#							} 
#							
#							if (($anded ne "Y") && $matches > 0) {
#								if (1) {$lh->log_print("TEMPLATE SEARCH WITH OR CONDITIONS $comp:\tFOUND A MATCH: $line")};
#								#&inserterrorevent($datasession,$debug,$lh,$server_id,$srvmgrvars{server_name},$errors[$error][4],$errors[$error][7],$errors[$error][8],$errors[$error][9])
#								my @args = ($server_id,$srvmgrvars{server_name},$errors[$error][4],$errors[$error][7],$errors[$error][8],$errors[$error][9]);
#								eval{$client->call('errorinsert',@args)};
#								if ($@) {$lh->log_print("ERROR: Could not report event! :\t $@")}
#							}
#			} els
			print "We are searching for error string: $errors[$error][0]\n";
			if ($line =~ /$errors[$error][0]/){ #we are not using a template, so whole line for string
				if (1) {$lh->log_print("STRING SEARCH FOR  $comp: $errors[$error][0] :\tFOUND A MATCH: $line")};
				
				#errorinsert args = ($sft_elmnt_id,$server,$event_string,$usr_event_level,$usr_event_type,$usr_event_sub_type,$time, $error_defs_id,$cc_alias,$host)
				


				$line =~ s/'/''/g; #pad quotes for sql insert
				
				$line = $line . "\n\nERROR STRING FOUND ON HOST = $host.\nERROR FILE = $filepath";
				my $datestring = &getdatestring();

				my @args = ($server_id,$srvmgrvars{server_name},$line,$errors[$error][2],$errors[$error][3],$errors[$error][4],$datestring, $errors[$error][1],$comp,$host);
				eval{$client->call('errorinsert',@args)};
				if ($@) {$lh->log_print("ERROR: Could not report event! :\t $@")}
			}

    }
}


##############################################################################################################
#sub processpids ($line) - reads line from server log, parses pids and task ids
#############################################################################################################

sub processpids {
	
	
	my $line = shift;
	chomp $line;
	my $tidsearch = shift;#only search for created tids if starting up - otherwise file new event will will catch it
	if ($debug) {$lh->log_print("SERVER LINE = $line")};
			
		  if ($tidsearch) {#only insert creation pids on startup
		 	
				if  ($line !~ /Server Scheduler/ && $line =~ /ProcessCreate/) {
					#print $line;
								
					my $pid;
					my $cc_name;
					my $tid;
					my $cc_alias;
					my $linematch;

					
					#added 3/23/2009 - support for languages in servermgr
					if ($lang eq "FRA") {
						
						if ($line =~ /PID SE =\s+(\d+)\s+\)\s+\w+\s+([a-zA-Z_0-9-]+)/) {
								print "matched a $lang pattern\n";
								#french version 
								$pid = $1;
								$cc_alias = $2;	
								$linematch =1;
						}	
					} 
						#then check the old matches...which are version specificish
					else {
					#siebel 7 changed many component names to include a (ENU) - notice the or | expresion in ($2) 
			
							if ($line =~ /OS pid = (\d+)\)\s+for\s+([a-zA-Z_0-9-\s]+\(\w+\) |[a-zA-Z_0-9-\s]+)with task id (\d+)/) {
								$pid = $1;
								$cc_name = $2;
								$tid = $3;
								$linematch =1;
							} elsif ($line =~ /OS pid =\s+(\d+)\s+\)\s+for\s+([a-zA-Z_0-9-]+)/) {
								#this is the siebel 8 version - has no with task id message, has component alias so no spaces allowed
								$pid = $1;
								$cc_alias = $2;	
								$linematch =1;
							} 			
					}

					if ($debug) {$lh->log_print("pid = $pid cc_name = $cc_name cc_alias = $cc_alias tid = $tid")}
					
					if ($linematch) {
						vadmin::data1::insertpid($datasession,$debug,$lh,$srvmgrvars{server_name},$tid,$pid,$cc_alias,$cc_name,$host,$appserver_id);
					} else {
						$lh->log_print("WARNING: FAILED to find PID match for line = $line");
					}
					#$task_id,$pid,$cc_alias,$cc_name
					
					#insert into db
				}
		   }

		
		if ($tidsearch) {#only insert creation pids on startup
			if ($line =~ /Server Scheduler/) {
						$line =~ /OS pid = (\d+)\)[a-zA-Z_0-9-\s]+with task id (\d+)/;

						
						if ($debug) {$lh->log_print("finding based on tid - TID = $2")};
						findbasedontid($2);

					}
		}
		
		
		
			if ($line =~ /Process completed Successfully/) {
				$line =~ /:\d+\s+[a-zA-Z_0-9-]+\s+(\d+)/;

				#print "PROCESS COMPLETE = $1 - Deleteing Key $1\n";
				if (1) {$lh->log_print("PROCESS COMPLETE = $1 - Deleteing Key $1")};
				vadmin::data1::deletepidbytid($datasession,$debug,$lh,$1,$appserver_id);

			}
		
			if ($line =~ /Process exited with error/) {
				$line =~ /:\d+\s+[a-zA-Z_0-9-]+\s+(\d+)/;

				#print "PROCESS EXITED WITH ERROR = $1 - Deleteing Key $1\n";
				if (1) {$lh->log_print("PROCESS EXITED WITH ERROR = $1 - Deleteing Key TID $1")};
				vadmin::data1::deletepidbytid($datasession,$debug,$lh,$1,$appserver_id);
			}	
		

			if ($line =~ /Process was terminated/) {
				$line =~ /:\d+\s+[a-zA-Z_0-9-]+\s+(\d+)/;

				#print "PROCESS EXITED WITH ERROR = $1 - Deleteing Key $1\n";
				if (1) {$lh->log_print("Process was terminate = $1 - Deleteing Key TID $1")};
				vadmin::data1::deletepidbytid($datasession,$debug,$lh,$1,$appserver_id);
			}	

			#CO 11/10/2007 - Siebel 8 messages
			if ($line =~ /Process (\d+) was terminated/) {
				#print "PROCESS EXITED WITH ERROR = $1 - Deleteing Key $1\n";
				if (1) {$lh->log_print("Process was terminate = $1 - Deleteing PID $1")};
				vadmin::data1::deletepidbypid($datasession,$debug,$lh,$1,$host);
			}	

			if ($line =~ /Process (\d+) exited with error/) {
				#print "PROCESS EXITED WITH ERROR = $1 - Deleteing Key $1\n";
				if (1) {$lh->log_print("Process exited with error = $1 - Deleteing PID $1")};
				vadmin::data1::deletepidbypid($datasession,$debug,$lh,$1,$host);
			}
			
			if ($line =~ /Process (\d+) completed Successfully/) {
				$line =~ /:\d+\s+[a-zA-Z_0-9-]+\s+(\d+)/;

				#print "PROCESS EXITED WITH ERROR = $1 - Deleteing Key $1\n";
				$lh->log_print("Process was terminate = $1 - Deleteing Key TID $1");
				vadmin::data1::deletepidbytid($datasession,$debug,$lh,$1,$appserver_id);
			}	
	}


##############################################################################################################
#sub processpids ($tid) - opens log directory and looks for file with particular tid - then parses component and pid from that file
#############################################################################################################


sub findbasedontid {

my $tid = shift;
my $count;
my %files = undef;
my ( $file, $filename, $comp);
opendir (DIR, "$logdir") || $lh->log_print("in findbasedontid could not open $logdir");
	foreach $filename ( readdir DIR ) {
		my $file = $filename;
			if ($file =~ /(.*?)_$tid/ ) {
				my $compname = $1;
				if ($debug) {$lh->log_print("found component = $compname  from $tid\n")}
				
				open( PFH, "$logdir$file" )or $lh->log_print("tid: couldnt open $file");
				while (<PFH>) {
						if ($count < 1) {
							$_ =~ /\b($compname)\b \b([0-9]+)\b \b([0-9]+)\b/;
								if ($debug) {$lh->log_print("found in sub file $2,$3,$1")};
								vadmin::data1::insertpid($datasession,$debug,$lh,$srvmgrvars{server_name},$2,$3,$1,undef,$host,$appserver_id);
							$count++;
						}
				}
				close PFH or $lh->log_print("died $!");
			}	
	}
closedir DIR || $lh->log_print("died $!");
}

##############################################################################################################
#sub  parsefrmfstline($fh) - opens fh passed and parses comp,tid,pid and inserts them
#############################################################################################################

sub parsefrmfstline {

sleep(1);
my $fh = shift;
my $count;
my ($line);
	
	if ($fh =~ /srvrmgr/) {
		open( NFH, "$fh" ) || $lh->log_print("couldnt open $fh");
		while ($line = <NFH>) {
				if ($count < 1) {
					if ($line =~ /\bsiebel\b \b([0-9]+)\b/) {
						if ($debug) {$lh->log_print("ON NEW FILE we found A SRVRMGR LOG FILE parsed $1 as pid")};
						vadmin::data1::insertpid($datasession,$debug,$lh,$srvmgrvars{server_name},undef,$1,"ServerMgr",undef,$host,$appserver_id);

						#comp tid pid
					}	
					$count++;
				} else { close NFH || $lh->log_print("died $!");	 
						 $line = undef;}
		}
	
	
	} else {

		open( NFH, "$fh" ) || $lh->log_print("couldnt open $fh");
		while ($line = <NFH>) {

			print "\n\n==============$line================\n\n";
				if ($count < 1) {
					# updated 8/19/2006 - added _ - allows harvesting of component names with _ in it
					if ($line =~ /\b([a-zA-Z_]{5,})\b \b([0-9]+)\b \b([0-9]+)\b/) {
						if ($debug) {$lh->log_print("ON NEW FILE we found the file and parsed $1 $2 $3 from the new file")};
						
						vadmin::data1::insertpid($datasession,$debug,$lh,$srvmgrvars{server_name},$2,$3,$1,undef,$host,$appserver_id);

						#comp tid pid
					}	
					$count++;
				} else { close NFH || $lh->log_print("died $!");	 
						 $line = undef;}
		}
	}#end else		
}


##############################################################################################################
#sub createfilehash  () - used to set the global variable %files with a hash of files on startup.  That way
#starting proc2 will not ananalze old errors from previous log files. %files set to undef if server is stopped
#while proc2 is running, then created dynamically within parsecomp function
#############################################################################################################

sub createfilehash {
    %files = undef;
	my ( $file, $filename, $size, $comp );

	my $srvrfile = "$srvmgrvars{enterprise}.$srvmgrvars{server_name}.log";
	# print "SRVR FILE = $srvrfile\n";
	$size = (-s "$logdir$srvrfile");
	$files{$srvrfile} = $size;


    opendir DIR1,
      "$logdir"
      || $lh->log_print(
        "could not open $logdir directory");
    foreach $filename ( readdir DIR1 ) {
        my $file = $filename;
		
        foreach $comp (@comps) {
            if ( $file =~ /$comp/) {
                
				$size = (-s "$logdir$filename");
				$files{$file} = $size;
                 # &getloglines("$logdir$filename");

            }
        }
    }
    closedir DIR1 || $lh->log_print(" died $!");
}

#old shitty sub - 

sub checkerror {
    my %ehash = @_;
    if ( $ehash{ERROR} ) {
        $lh->log_print( $ehash{ERROR} );
        return 1;
    }
}

#old shitty sub -
sub checkscerr {
    my $err = shift;
    if ( $err =~ m/Error:/ ) {
        $lh->log_print($err);
        return 1;
    }
}

sub getdatestring {
		my $datestring;
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
				localtime(time);

	if ($db = 'MSSQL') {
		#01/01/1998 23:59:15
		$year = $year + 1900;
		$mon = $mon + 1;
		$datestring = "$mon/$mday/$year $hour:$min:$sec"		
	}

	return $datestring;
}
