
use vadmin::vconfig;
use vadmin::data1;
use strict;
use Log::Logger;
#use Win32::Service;
use Win32;
use Mail::Sender;
use Frontier::Daemon;
use Win32::Process;

use Date::Calc;
use Win32::TieRegistry;

use Cwd 'abs_path';	    # aka realpath()
my $rootpath = abs_path("..");


my $host = Win32::NodeName;

use vars qw(%hup $datasession);

%main::hup;    #hash of user preferneces
$main::datasession;


my (  $key, %srvmgrvars );

print "Log Path = $rootpath/log/vcs.log\n"; 

my $lh = new Log::Logger "$rootpath/log/vcs.log" || new Log::Logger "vcs.log";    # global log file

$lh->log_print("HOST = $host");
$lh->log_print("Start up.......");          # first log comment


if ( checkerror( %hup = vadmin::vconfig::openlog() ) ) {  
    die;  # create user preference hash or die
} 

my $debug = $hup{DEBUG};
my $db = $hup{DBTYPE};

$datasession = vadmin::data1::odbcsess($debug,$lh, $hup{VODBC}, $hup{USERNAME}, $hup{PASSWORD} ); 
$lh->log_print("Data Session initialized.......");

my $vcsport = $hup{CCPORT};

if ($db =~ /ORACLE/) {
 vadmin::data1::alterdateformat($datasession,$debug,$lh);
}


################################
# Moudule specific global vars #
################################

my @currentevents;
my @currentrules;
my %reactionids; #used a global variable... too exhausting to do it any other way
my $i;
my $href;

##############################################################################################################
# getallevents will get all events and process them one by one, sending off communications or reactions per event#
##############################################################################################################


#while (1) {
#	my $interval = &vadmin::data1::getinterval($datasession);
#	if ($debug) {$lh->log_print("interval = $interval")};
#	&getallevents;
#	sleep($interval);
#}

#do this once on startup to clear out events
#&getallevents;

$lh->log_print("Processed stored events...");
$lh->log_print("Starting the VCS on ADDRESS: $hup{CENTRALSERVER} port: $vcsport");

my $d = Frontier::Daemon->new(
			  methods => {
					errorinsert =>\&errorinsert
				 },
			  LocalAddr => $hup{CENTRALSERVER},   				      
			  LocalPort => $vcsport,
			  );

#$hup{CENTRALSERVER}
$lh->log_print("Errors on startup: $@");
print "started frontier\n";

##############################################################################
# Modify this function on 4/7/2006 by Anuva technology for the enhancement of VA2.
#Add one more scalar varible $filepath for fetching the path of the Error String
#Add this variable $lh->log_print to make a record in log file
#add the $filepath variable in a passing parameter of the vadmin::data1::inserterrorevent() function
##############################################################################

sub errorinsert {
	my ($sft_elmnt_id,$server,$event_string,$usr_event_level,$usr_event_type,$usr_event_sub_type,$event_time,$error_defs_id,$cc_alias,$host,$analysis_rule_id,$filepath) =@_;
	my $count = @_;

	$event_string = substr($event_string,0,1999);
		$lh->log_print("RECIVIED AN ERROR EVNT: sft_elmnt_id = $sft_elmnt_id | sever = $server | event_string = $event_string | usr_event_level = $usr_event_level | usr_event_type = $usr_event_type | user_event_sub_type = $usr_event_sub_type | event_time = $event_time | error_defs_id = $error_defs_id | cc_alias = $cc_alias | host = $host | filepath = $filepath");
	$event_time = &getdatestring();

	my $errorid = &vadmin::data1::inserterrorevent($datasession,$debug,$lh,$sft_elmnt_id,$server,$event_string,$usr_event_level,$usr_event_type,$usr_event_sub_type,$event_time,$error_defs_id,$cc_alias,$host,$analysis_rule_id,$filepath);
	&getallevents($errorid);
	return 1;
}


sub getallevents {
		my $errorid = shift;
		@currentevents = getaevent($datasession,$debug,$lh,$errorid);
		@currentrules = getnoterules($datasession,$debug,$lh);
		#my $i;
		#my $href;
		# for (@currentevents) #array of all non processed error events
		# -> processevent(%eventhash) # process each one in turn - (there will only  be one now)
		#	-> fire_reaction({%eventhash},{%{$currentrules[$i]}});
		#	-> comun_process (%eventhash)  #if a rule matches event type, find a schedule
		#		-> get_admins(.$schedule_id) #get all admins who match a schedule
		#			-> use_com_channel(..%admin); fire the communication for admin for each com channel
		
		for $href (@currentevents) {
				processevent(%$href);  #pass derefrenced hash to process event sub
		}
		return 1;
}
###############################################################################
#process event - compare  event to hash of all rules
###############################################################################

sub processevent {  #take each error and compare it to all notification rules
	
	my %eventhash = @_;
	my $i;
	my $key;
	my $fired;
	
	%reactionids = undef;
	for $i (0..$#currentrules) { #curent rules is an array of hashes of notification rules		
		my $fire;
		my ($gcount,$rcount);  
		$gcount= 0;
		#notify_all field is translated to N because oracle will only return a 1 char header for a 1 char field....
		if ($currentrules[$i]{N} =~ /Y/) {  #first to check if rule is "notify_all", format for sending 
			$fire =1;
			#print "fire 1\n";
			} else {  # the rule is not notify all, so we must compare every field to the event (anded) - only if they all match does the rule match the event-
						#if ($currentrules[$i]{ev_sft_elmnt_id}) {
						#	$gcount++; 
						#	if ($debug) {$lh->log_print("GCOUNT INCREMENTED ON ev_sft_elmnt_id")};
						#	if ($eventhash{sft_elmnt_id} == $currentrules[$i]{ev_sft_elmnt_id}) {$rcount++} 
						#} 
						
						if ($currentrules[$i]{type}) {
							$gcount++; 

							if ($debug) {$lh->log_print("TESTING FOR NOTFICATION RULE TYPE \"$currentrules[$i]{type}\"  = EVENT TYPE  \"$eventhash{type}\"")};
							if ($currentrules[$i]{type} eq $eventhash{type}) {$rcount++} 
						} 

						
						if ($currentrules[$i]{ev_event_sub_type}) {
							$gcount++; 
			
							if ($debug) {$lh->log_print("TESTING FOR NOTFICATION RULE SUB TYPE \"$currentrules[$i]{ev_event_sub_type}\"  = EVENT SUB TYPE  \"$eventhash{event_sub_type}\"")};
							if ($eventhash{event_sub_type} eq $currentrules[$i]{ev_event_sub_type}) {$rcount++} 
						} 
						if ($currentrules[$i]{ev_event_level}) {
							$gcount++; 
							if ($debug) {$lh->log_print("TESTING FOR NOTFICATION RULE LEVEL \"$currentrules[$i]{ev_event_level}\"  = EVENT LEVEL  \"$eventhash{event_time}\"")};
							if ($eventhash{event_level}  eq $currentrules[$i]{ev_event_level}) {$rcount++} 
						} 
						##if ($currentrules[$i]{ev_event_time}) {
						##	$gcount++; 
						##	if ($debug) {$lh->log_print("TESTING FOR NOTFICATION RULE EVENT TIME \"$currentrules[$i]{ev_event_time}\"  = EVENT TIME  \"$eventhash{event_time}\"")};
						##	if ( $eventhash{event_time} eq $currentrules[$i]{ev_event_time}) {$rcount++} 
						##} 
						if ($currentrules[$i]{ev_event_string}) {
							$gcount++; 
								if ($debug) {$lh->log_print("TESTING FOR NOTFICATION RULE EVENT STRING \"$currentrules[$i]{ev_event_string}\"  = EVENT STRING  \"$eventhash{event_sting}\"")};
								if ($eventhash{event_string}  eq $currentrules[$i]{ev_event_string}) {$rcount++} 
						}
						
						#if $g(ood)count matches $r(eal)count, we have matched all anded conditions and must fire 
						if ($debug) {$lh->log_print("COUNT OF TESTS == $gcount : COUNT OF MATCHES == $rcount")}
						
						if ($gcount) { #if both values are null, the statement below will be true... which ain't good - this tests for null value first
								if ($debug) {$lh->log_print("gcount : $gcount == rcount : $rcount")}
								if ($gcount == $rcount) {$fire = 1}
						}
					}#end else
			

					my $retval = 1;
					if ($fire) { # send hash to communication server sub
								$fired = 1;
								if ($debug) {$lh->log_print("fired event for $eventhash{errorevent_id}, satisfying rule $currentrules[$i]{noteruleid}")};
								%reactionids =	fire_reaction({%eventhash},{%{$currentrules[$i]}});
								my $rids;
								#must use the {} braces to create an anonomyous array of hashes	
						
								print "rule name = $currentrules[$i]{name}";
								
								if ( comun_process({%eventhash},{%{$currentrules[$i]}}) ) { #comun_process should return a 1 if all sub components worked
									#mark the event processed - delete if system option says so
			
									vadmin::data1::updateeventstatus($datasession,$debug,$lh,$eventhash{errorevent_id});
									
									}

					}  #else do not process for this rule
	}# end for rule
	
	unless ($fired) {$lh->log_print("WARNING: Attempted to Process Error Event $eventhash{errorevent_id} - Found no satisfying Notification rule.")}
	return 1;
}

####################################
#
#
sub comun_process {#
	my @aoh = @_;
	my %eventhash =  %{$aoh[0]};  #this ugly syntax is for derefrencing the array of hashes passed in
    my %currentrule =  %{$aoh[1]};
	my $hash; 
	my @schedules;   #array of hashes of schedules
	my @schedid;

	# CO9/7/2007 - Changed default $retval = 0 by default, will change to 1 if sucess
	my $retval = 0;
	
	my @days = ('sunday','monday','tuesday','wednesday','thursday','friday','saturday');
	my ($day,$hour,$min)= (localtime)[6,2,1];
	if (length($min) == 1) {$min = "0".$min}
	my $catime = $hour.$min;

	@schedules = getschedules($datasession,$debug,$lh,$days[$day]); #get schedules for today
	for  $hash (@schedules) {
		my %hash = %$hash;
		my $startime = $hash{hour_start}.$hash{minute_start};
		my $endtime = $hash{hour_end}.$hash{minute_end};
		
		if ($hash{schedule_every} =~ /Y/) {   #schedule every qualifies
			push @schedid, $hash{schedule_id};
		} elsif ($catime >= $startime && $catime <= $endtime) {#otherwise check time
			push @schedid, $hash{schedule_id};
			}
	}

	foreach  (@schedid) {
		#print "################ $_ ##################\n";
		#get adminisntrators for each  schedule
		# CO - 9/7/2007 - if one of the schedules is processed, mark event processed
		if ( get_admins($_,{%eventhash},{%currentrule}) ) {
			$retval = 1;
		 }
	}

	unless (@schedid) {
		$lh->log_print("WARNING: Error Event Id: $eventhash{errorevent_id} satisfying Rule ID: $currentrule{noteruleid} was encountered, but there is no current Schedule to send notification to. Notification Abandoned");
		$retval = 0
	}

		return $retval;

}
 

sub get_admins {
	my @aoh = @_;
	my $sched_id = $aoh[0];
	my %eventhash =  %{$aoh[1]};
	my %currentrule =  %{$aoh[2]};
	my @admin = getadmins($datasession,$debug,$lh,$sched_id);
	my $retval = 0;
		
	#get admin comm channels
	#if no administrator is found for a schedule, don't bother sending a communication
	if (@admin) {

		for $href (@admin) {
			if (  use_com_channel({%$href},{%eventhash},{%currentrule}) ) {
				$retval = 1;	
			}
		}


	} 
	else {
	    $lh->log_print("WARNING: No Administrators found for Schedule Id: $sched_id.  Notification Abandoned.");
		$retval = 0;
	}
		
	return $retval;

}


sub use_com_channel {

	my @aoh = @_;
	my %comchannels; #hash that will be updated per com channel used
	my %admin =  %{$aoh[0]};
	my %eventhash =  %{$aoh[1]};
	my %currentrule =  %{$aoh[2]};
	my $sender;
	my $retval = 0;

	my (@comserver,$i);
	@comserver = vadmin::data1::getcomserver($datasession,$debug,$lh,$admin{administrators_id});
	unless (@comserver) {$lh->log_print("WARNING: No Communication Server found for Adminstrator Id: $admin{administrators_id}. Notification Abandoned");
	 return 0;
	}


	for $i (0..$#comserver) {
		my @reactreport;
		my $error;
		my $i;
		
		
		#######################################################################################################
		# first see if there are any reacion ids that have been routed our errored out, push into reactreport array
		if ($reactionids{ROUTED}) {
			push @reactreport,"\nREACTIONS ROUTED FOR THIS EVENT:\n";
			for $i (0..$#{ $reactionids{ROUTED}}) {
				my $rulename = vadmin::data1::getrulename($datasession,$debug,$lh,$reactionids{ROUTED}[$i]);
				push @reactreport,"$rulename\n";
				#print "RID FOR THE ROUTED REPORT: $reactionids{ROUTED}[$i] \n";
			}
		}

		if ($reactionids{ERRORS}) {
		   push @reactreport,"\n\nREACTION ERROR(S):\n";
			for $i (0..$#{ $reactionids{ERRORS}}) {
				#my $rulename = vadmin::data1::getrulename($datasession,$debug,$lh,$reactionids{ERRORS}[$i]);
				push @reactreport,"$reactionids{ERRORS}[$i]\n";
				#print "RID FOR THE ERROR REPORT: $reactionids{ERRORS}[$i] \n";
			}
		}
		#############################################################################################################
		#now go through and send a notification per type of notification system 
		#
		if ($comserver[$i]{type} =~ /smtp/) {
				
				my %conhash;
				#CO updated 1/1/2006 - allow users to set from option, if they use SMTP authentication
				$conhash{from} = $comserver[$i]{from} || $admin{email};
				$conhash{smtp} = $comserver[$i]{smtp_server};
				
				if ($debug) {$lh->log_print("smtp_authentication = " . $comserver[$i]{smtp_authentication})}
				#now get authentication parameters
				if ($comserver[$i]{smtp_authentication} =~ "TRUE") {		
						$conhash{auth} = "LOGIN"; #hard coded! eek. but hey, mail and login based auth should be enough eh?
						$conhash{authid} = $comserver[$i]{smtp_user};
						$conhash{authpwd} = $comserver[$i]{smtp_password};	
				}

				$conhash{Port} = $comserver[$i]{smtp_port} || 25;
				
				if ($debug) {
					$lh->log_print("Options for Communication Seve $comserver[$i]{smtp_server} :");
					for my $key (keys %conhash) {
						$lh->log_print("$key = $conhash{$key}");
					}
				}

				my $sender = undef;
				ref ($sender = new Mail::Sender({%conhash})) or $lh->log_print("Mail ERROR for for Error Event Id: $eventhash{errorevent_id}= $Mail::Sender::Error") and $error = 1;
	

				my ($msgstring,$substring);

				my $expired = &isnot_expired(); #
				#############################################
				# changed 7/20/2003 - VA2 no longer expires!!! freware!!!
				# changed message 4/5/2005 - to VA2 EVENT from Vadmin Event Detected for rule:

				if ($expired) {
					#CO 9/9/2007 - changed message to include Host
					 $msgstring = "Event Id:  $eventhash{errorevent_id}\nEvent Type: $eventhash{type}\nEvent Sub Type: $eventhash{event_sub_type}\nEvent Level: $eventhash{event_level}\nEvent Time: $eventhash{event_time}\nEvent Host: $eventhash{host}\nSiebel Server: $eventhash{sv_name}\n\nEvent String: $eventhash{event_string}\n\nFile Name: $eventhash{file_path}\n\n@reactreport";
					 $substring = "VA2 EVENT $eventhash{errorevent_id} for rule: \"$currentrule{name}\"";
					
				}	else {
					$msgstring = "WARNING!!! YOUR VA2 TRIAL LICENSE HAS EXPIRED.  PLEASE CONTACT RECURSIVE TECHNOLOGY (http://www.recursivetechnology.com) TO OBTAIN A VALID PRODUCTION LICENSE.";
					$substring = $msgstring;
					$lh->log_print("$msgstring");
				}
	
			
				print "msgstring = $msgstring\n substring = $substring\n";

				unless ($error) {
						(ref ($sender->MailMsg({to =>"$admin{email}", subject => $substring,
									 msg => $msgstring}))
							and $lh->log_print("Mail sent to $admin{email} for Error Event Id: $eventhash{errorevent_id}, Satisfying Notfication Rule Id: $currentrule{noteruleid}") and $comchannels{"SMTP"} = "$admin{email}	$eventhash{errorevent_id}	$currentrule{noteruleid}"	 	
						)
						or $lh->log_print("Mail ERROR for for Error Event Id: $eventhash{errorevent_id}= $Mail::Sender::Error")
						#update unprocessed notification queues
				}
				$sender = undef;

			} else {
				$lh->log_print("WARNING: Unrecoginized Communication Server Type : $comserver[$i]{type}. Notification Abandoned");
			}

	} # finished looping through the com servers

	# and $comchannels{"SMTP"} = $admin{email}
	#only now mark the error processed.... print out a report from %comchannels to which com channels error was sent to 
	my $comm;
	my $sucessfire;
	foreach $comm (keys %comchannels) {
		#print "SUCESSFULLY USED COMM CHANNEL $comm to send this: $comchannels{$comm}\n";
		$sucessfire++;
	}

	if ($sucessfire) {
		$retval = 1;
	} else {
		$lh->log_print("WARNING: Failed to send notification on any defined Notification channel.  Notification Abandoned");
		#do something else, like start beeping, etc, when all communication channels fail?
		$retval = 0;
	}
	

}

###########################
#fire reaction takes an event hash and rule hash and decides what reactions to fire for it
######
sub fire_reaction {
	my @aoh = @_;
	my $hash;
	my %eventhash =  %{$aoh[0]};  #this ugly syntax is for derefrencing the array of hashes passed in
    my %currentrule =  %{$aoh[1]};

	my @reactions = vadmin::data1::getreactions($datasession,$debug,$lh,$currentrule{noteruleid});
	my @routedreactions;
	my @reactionerrors;
	#get reactions
	# for each reaction, route it or execute, depending on the errorevent.host property
		for  $hash (@reactions) {
		my %hash = %$hash;
		my $reaction_def = $hash{rule_def};
		my $routehost;

		#print "HEEEEEEEEEEEEYYYYYYYYYYYYYYYYYY!!!!!!!!! got a rule def = $reaction_def\n !!!!!!!!!!";
			#check reaction type, 2= perl command - either routed or not routed
			if ($hash{type} == 2) {
				#print "REACTION TYPE ========== 1\nhost specific = $hash{host_specific}\n";
				if ($hash{host_specific}) {
					$routehost = $hash{host_specific};
					 #$routehost= vadmin::data1::getroutehost($datasession,$debug,$lh,$eventhash{errorevent_id});
					if ($routehost) {
						#write routing message - type 2 = lsm perl command
						$lh->log_print("Routed Reaction of type 2 to $routehost");
						sendsysmsg($datasession,$debug,$lh,2,$hash{reaction_id},$routehost);
						push @routedreactions,$hash{reaction_id};
					} 
					else{
						#raise reaction rule error - because the rule called for a event with a specific
						#host, yet the event did not have one.
						my $error = "ERROR: Reaction: \"$hash{name}\" could not be routed because the Notification Rule associated with it requires that a host be present in the errorevent. There was no Host listed in the error event.  Please change your error event generator or notification rule.";
						$lh->log_print("$error");
						#insert_react_hist($datasession,$debug,$lh,$hash{reaction_id},$eventhash{errorevent_id},$error);		
						push @routedreactions,$hash{reaction_id};
						push @reactionerrors, $error;
					} 
				} 
				else{
					#it is not host specific, route the perl request to cc
					#&peval($hash{reaction_id},2);
					&openpevalproc($hash{reaction_id},2);
					push @routedreactions,$hash{reaction_id};
				}
			
			#reaction type 3 = a srvrmanger command
			} 
			elsif ($hash{type} == 3)  {
				if ($hash{host_specific} && $hash{sv_name}) {#$eventhash{sv_name}
					#check to see if it is a srvrmgr type and it has a srvrmgr listed
					#if so route to the appropriate siebsrvr - type 3 = srvrmgr
					$lh->log_print("Routed SiebSrvr Reaction(type 3) to $eventhash{sv_name}");
					sendsysmsg($datasession,$debug,$lh,3,$hash{reaction_id},$hash{sv_name},$hash{sv_name});
					push @routedreactions,$hash{reaction_id};
				} else {
					#if not raise the reaction error
					my $error = "ERROR: Reaction: \"$hash{name}\" could not be routed because it requires that a sv_name and host be present in the Reaction.\n";
					$lh->log_print("$error");
					#insert_react_hist($datasession,$debug,$lh,$hash{reaction_id},$eventhash{errorevent_id},$error);
					push @routedreactions,$hash{reaction_id};
					push @reactionerrors, $error;
				}
			#reaction type 4 = .bat command - check to see whether it is routed or local
			} 
			elsif ($hash{type} == 4)  {
				if ($hash{host_specific}) {
					#do network check? that we have that host else write a reaction rule error
					$routehost = $hash{host_specific};				
					#$routehost= vadmin::data1::getroutehost($datasession,$debug,$lh,$eventhash{errorevent_id});
					if ($routehost) {
						  #write routing message - type 4 = lsm system command
                         $lh->log_print("Routed Reaction of type 4 to $routehost");
						 sendsysmsg($datasession,$debug,$lh,4,$hash{reaction_id},$routehost);
						 push @routedreactions,$hash{reaction_id};
					} 
					else{
						#raise reaction rule error - because the rule called for a event with a specific
						#host, yet the event did not have one.
						my $error = "ERROR: Reaction: \"$hash{name}\" could not be routed because the Notification Rule associated with it requires that a host be present in the errorevent. There was no Host listed in the error event.";
						$lh->log_print("$error");
						#insert_react_hist($datasession,$debug,$lh,$hash{reaction_id},$eventhash{errorevent_id},$error);		
						push @reactionerrors,$hash{reaction_id};
						push @routedreactions,$hash{reaction_id};
						} 
				} 
				else{
					#it is not host specific, route the batcommand to peval.exe and execute now
					#&peval($hash{reaction_id},4);
					&openpevalproc($hash{reaction_id},4);
					push @routedreactions,$hash{reaction_id};
				}
			}
		
		}# end for %hash (hash of reactions for the notification rule)

		$reactionids{ROUTED} = [@routedreactions];
		if (@reactionerrors) {$reactionids{ERRORS} = [@reactionerrors]}
		return %reactionids;
}


##################################################################################3
#fire peval

sub peval {
	my $i;
	my $reaction_id = shift;
	my $type = shift;
	
			my $random = rand 100000;
			my $args= " peval.exe $reaction_id $type ";
			#> ./reactionlogs/reaction_".$reaction_id."_".time().$random.".reactionlog";
			#my $args = " peval.exe";

			open(DOSPROMPT, "| $args") or $lh->log_print("$args\nCannot open dos $!"); 
			close(DOSPROMPT);
			$lh->log_print("FIRED CC REACTION_ID: $reaction_id : $args");

}


sub openpevalproc {
		my ($i,$handle);
	my $reaction_id = shift;
	my $type = shift;

	eval {
	Win32::Process::Create($handle,
							"./peval.exe",
							" $reaction_id $type",
							0,
							NORMAL_PRIORITY_CLASS,
							".") || die "$!";
		};


	if ($@) {
	$lh->log_print("ERROR STARTING PROC $@"); 
	return "ERROR";
	  }				

}
########################################################################
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
	open (LIC,"< va2.lic") or $error = "CRITICAL ERROR - COULD NOT LOCATE VA2 LICENSE FILE\n";
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

#########################################################################
sub checkerror {
    my %ehash = @_;
    if ( $ehash{ERROR} ) {
        $lh->log_print( $ehash{ERROR} );
        return 1;
    }
}

########################################################################
#
#

sub getdatestring {
		my $datestring;
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
				localtime(time);
		$year = $year + 1900;
		$mon = $mon + 1;

	#default
	$datestring = "$mon/$mday/$year $hour:$min:$sec";
	print "##############db type = $db ###################\n";

	if ($db =~ /DB2/ || $db =~ /MYSQL/) {
		$datestring = "$year-$mon-$mday-$hour.$min.$sec";	
	} 
	if ($db =~ 'MSSQL' || $db =~ /ORACLE/ ) {
		$datestring = "$mon/$mday/$year $hour:$min:$sec";		
	}

	print "################# $datestring ################";
	return $datestring;
}