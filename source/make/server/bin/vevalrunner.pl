# file: tcp_echo_serv2.pl
# Figure 5.4: The reverse echo server, using IO::Socket

# usage: tcp_echo_serv2.pl [port]

use strict;
use IO::Socket qw(:DEFAULT :crlf);
use constant MY_ECHO_PORT => 15505;
use vadmin::vconfig;
use vadmin::data1;
#use strict;
use Log::Logger;
use Win32;
use Date::Calc;
use Win32::OLE qw( in );
use Net::Ping;
use Time::Local;
use Win32::OLE;
use Win32::OLE::Const;

use IO::Select;
use Frontier::Client;

use Win32::TieRegistry;

use Cwd;
use Cwd 'abs_path';	    # aka realpath()

use vars('$datasession','$lh','$debug');
$main::datasession;
$main::lh;
$main::debug;


my $rootpath = abs_path("..");


my $port  = $ARGV[0] || MY_ECHO_PORT;
my $notime = $ARGV[1];
my $type = $ARGV[2];
my $ruleid = $ARGV[3];

print "PORT = $port";

###########################################################################
my $host = Win32::NodeName;
my (  $key, %srvmgrvars );
my %hup;    #hash of user preferneces


print "Log path = $rootpath/log/vevalrunner.log";
$lh = new Log::Logger "$rootpath/log/vevalrunner.log" || new Log::Logger "vevalrunner.log";    # global log file

$lh->log_print("HOST = $host");
$lh->log_print("Start up.......");          # first log comment

if ( checkerror( %hup = vadmin::vconfig::openlog() ) ) {  
    die;  # create user preference hash or die
} 
 


#find the VCS install path, and use the the lib directory 
my $curdir = cwd;
$debug = $hup{DEBUG};
my $db = $hup{DBTYPE}; 

$datasession = vadmin::data1::odbcsess($debug,$lh, $hup{VODBC}, $hup{USERNAME}, $hup{PASSWORD} );

$lh->log_print("Data Session initialized.......");
$lh->log_print("DATABASE TYPE = $db");




#ALTER SESSION
if ($db =~ /ORACLE/) {
 vadmin::data1::alterdateformat($datasession,$debug,$lh);
}


#############################################################################
#start up other data sessions......

my @arrayofdatasources = vadmin::data1::getaoh($datasession,$debug,$lh,"select alias \"alias\", name \"name\", username \"username\", password \"password\" from data_source");


my %datasource;  # hash of datasources that will be pre-started 

foreach my $dshash (@arrayofdatasources) {
		my %deref = %$dshash;

		$lh->log_print("Data session connection pooling initializing for Data Source: $deref{alias}"); 
		$datasource{$deref{alias} } = vadmin::data1::odbcsesspool($debug,$lh,$deref{name},$deref{username},$deref{password} );
		print "alias = $deref{alias};\n";
		
	}
	
##############################################################################


use lib "./lib"; #does not give an error on wrong path.....

if ($debug) {$lh->log_print("Lib Directory = $curdir/lib")}


$lh->log_print("Connecting to VCS server: http://$hup{CENTRALSERVER}:$hup{CCPORT}/RPC2");






my $url  = "http://$hup{CENTRALSERVER}:$hup{CCPORT}/RPC2";
my $client = Frontier::Client->new( url   => $url,
					debug => $debug,
				  );

###########################################################################

#my $entobj = vadmin::siebsrvobj->newobj($datasession,$debug,$lh,'siebel');


print "CHECKING INPUT PARAMATERS - notime = $notime,  port =  $port, type =  $type, ruleid =  $ruleid\n";


if ($notime) {
	&notimesection;
	exit; #call once and die
}


my $sock;
my $session;
my $quit = 0;
$SIG{INT} = sub { $quit++ }; 

		 
		 
$sock = IO::Socket::INET->new( Listen    => 20, 
                                  LocalPort => $port,
                                  Timeout   => 60*60,
                                  Reuse     => 1) 
or $lh->fail("Can't create listening socket: $!");




$lh->log_print("waiting for incoming connections on port $port...");
while (!$quit) {
	next unless my $session = $sock->accept;
	
	my $peer = gethostbyaddr($session->peeraddr,AF_INET) || $session->peerhost;
	my $port = $session->peerport;
	$lh->log_print("Connection from [$peer,$port]");

	while (<$session>) {
		##

		####################################################################
		#ANALYSIS RULE SECTION 

		if ($_ =~ /ANALYSIS:/) {
				my @eval;
				my $retval; 
				chomp;

			my $analysis_rule_id;
			my ($sv_name,$error_string,$cc_alias,$host);
			$_ =~ /: (\d+)/;
			$analysis_rule_id = $1;
			if ($debug) {$lh->log_print("Recieved Analysis Id: $analysis_rule_id")}
			@eval = &getarule($analysis_rule_id);
			
			unless ($eval[0]) {
				#defect = 10/7/2003 - rules were being violated because they were inactive but had been routed to the evalrunner
				$lh->log_print("RECIEVED A REQUEST: $_ TO EXECUTE A INVALID RULE ID = $analysis_rule_id");
				goto ENDARULE;
			}
			
			if ($debug) {$lh->log_print("Analysis Rule type = $eval[1]")}
			#if ($eval[1] =~ "Perl") { #don't check type
				#print $eval[0];
				$retval = 0; #set retval to zero - in case the analysis rule does not
				if ($debug) {$lh->log_print("Analysis Rule def = $eval[0]")}
				eval $eval[0];
				if ($@) { 
					$lh->log_print("EVALED ERROR FOR ANALISIS ID: $analysis_rule_id =".$@);
					$@ =~ s/\'/\'\'/g; #pad error string, pad single quotes which screw up sql (compare this to 20 lines of vb ;)
					my $error = substr($@,0, 195);
					vadmin::data1::udateaoerr($datasession,$debug,$lh,$analysis_rule_id,"WARNING: Partial analysis Rule execution Error: $error");
					vadmin::data1::sendsysmsg($datasession,$debug,$lh,'ARULEUPD'); #send a message to update the error hash
					
					my $datestring = &getdatestring;
		 			my @args = (undef,undef,"WARNING: Partial analysis Rule execution Error: $error",undef,"RULERROR","ANALYSIS_RULE",$datestring,undef,undef,$_,undef);					
					eval{$client->call('errorinsert',@args)};
					if ($@) {$lh->log_print("ERROR: Could not report event! :\t $@")}
					
				
					
					goto ENDARULE;
					#return 0; #don't go on to insert a matching error...cause the script failed
			}
				print "RETVAL = $retval\n";


			unless ($retval) {
				my $href;
				my @arrayofdefs = vadmin::data1::insert_arule_error($datasession,$debug,$lh,$analysis_rule_id);
				$lh->log_print("rule id: $1 returned a false value - Searching for associated Error Definitoins and sending an event.");
				
				unless (@arrayofdefs) {$lh->log_print("WARNING!!! ANALYSIS RULE ID = $analysis_rule_id SHOULD GENERATE AND EVENT BASED ON RETURNING A FALSE VALUE.  HOWEVER, IT HAS NO ERROR DEFINITION ASSOCIATED WITH IT SO IT WILL NOT GENERATE AN EVENT.")};

				for $href (@arrayofdefs) { #submit a error event for each error definition for this analysis rule
					my %Data = %$href;  #derefrenced hash to process from array of hashes

					if ($debug) {$lh->log_print("Inserted an error event based on rule id: $analysis_rule_id returning a false value - err definition = ")};
					
					$error_string = substr($error_string,0,253); #otherwise sv_string could exceed size for errorevent field
					my $datestring = &getdatestring();
				    
					if ($debug) {$lh->log_print("Inserting an error event based on rule id: $analysis_rule_id returning a false value")};
				
					my @args = ($Data{sf_elmnt_id},$sv_name,$error_string,$Data{ev_level},$Data{ev_type},$Data{ev_sub_type},$datestring,$Data{error_defs_id},$cc_alias,$host,$analysis_rule_id);
					
					$lh->log_print("ERROR EVENT ARGUMENTS for violated rule id  $analysis_rule_id  : @args");
					eval{$client->call('errorinsert',@args)};
					if ($@) {$lh->log_print("ERROR: Could not report event! :\t $@")}
				}


			} 
		
			#evaluate retval.... if true do nothing, if false enter error event
			#if $@ mark inactive and update returned errors in analysis_rule
			ENDARULE:
			eval{print $session "SUCESSREQ: $analysis_rule_id\n"};
				if ($@) {$lh->log_print("$@\nunforunately, the socket must be dead, because the filehandle is invalid.  Restart the eval runner")};
				#this is a fatal error....BUT...the sal will kill us anyway if we can't send a response
			

		}
		#print $session "RETVAL = $retval ERRORS = $@ \n";
	##

####################################################################
#COLLECTOR RULE SECTION
	
	
		if ($_ =~ /COLLECTOR RULE:/) {
				my @eval;
				my $retval; 
				chomp;
			my $datestring;
		
			$_ =~ /: (\d+)/;

			if ($debug) {$lh->log_print("Recieved Collector Id: $1")};
			my $collectorid = $1;  #better save $1 for later
			@eval = &getstatrule($1);

			unless ($eval[0]) {
				#defect = 10/7/2003 - rules were being violated because they were inactive but had been routed to the evalrunner
				$lh->log_print("RECIEVED A REQUEST: $_ TO EXECUTE A INVALID RULE ID = $1");
				goto ENDCOLLECTOR;
			}
			

					print "evaled perl string = $eval[0]\n";
					eval $eval[0];
					if ($@) { 
						$lh->log_print("EVALED ERROR FOR COLLECTOR ID: $collectorid =".$@);
						$@ =~ s/\'/\'\'/g; #pad error string, pad single quotes which screw up sql (compare this to 20 lines of vb ;)
						my $error = substr($@,0, 195);
						vadmin::data1::updatestaterr($datasession,$debug,$lh,$collectorid,"WARNING: Partial Collector Rule execution Error: $error");
						vadmin::data1::sendsysmsg($datasession,$debug,$lh,'STATUPD'); #send a message to update the error hash


						my $datestring = &getdatestring;
		 				my @args = (undef,undef,"WARNING: Partial Collector Rule execution Error: $error",undef,"RULERROR","COLLECTOR",$datestring,undef,undef,$_,undef);					
						eval{$client->call('errorinsert',@args)};
						if ($@) {$lh->log_print("ERROR: Could not report event! :\t $@")}
						
						
						
						goto ENDCOLLECTOR;  #don't go on to insert a matching error...cause the script failed
						}
					#$retval is a variable returned from the collector defined by the user
					print "RETVAL = $retval\n";
						

				
				
				my $datestring = &getdatestring();

				
				if ($retval > 0) {
					vadmin::data1::insert_statval($datasession,$debug,$lh,$retval,$datestring,$collectorid);
				}
				
				ENDCOLLECTOR:	
				eval{print $session "SUCESSREQ: $collectorid\n"};
					if ($@) {$lh->log_print("$@\nunforunately, the socket must be dead, because the filehandle is invalid.")};

		}
	
	
	
#################################################3	
	
	}
	
	$lh->log_print("Connection from [$peer,$port] finished");
	close $session;
	#close $sock;
}
	


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


sub getarule {
	my $rule_id = shift;
	my $i;	
	my $sql = "select rule_def \"rule_def\", type \"type\" from analysis_rule where active = 'Y' and analysis_rule_id = $rule_id";
	my @aobjarrays = vadmin::data1::getaoh($datasession,$debug,$lh,$sql);
	my @retvals;
	
	for $i (0..$#aobjarrays) {
	  @retvals = ($aobjarrays[$i]{rule_def},$aobjarrays[$i]{type});
	  #print @retvals;
	 
	}	

	return @retvals;
}

############################################################################################
sub getstatrule {
	my $rule_id = shift;
	my $i;	
	my $sql = "select rule_def \"rule_def\", type \"type\" from collector where active = 'Y' and collector_id = $rule_id";
	my @aobjarrays = vadmin::data1::getaoh($datasession,$debug,$lh,$sql);
	my @retvals;
	
	for $i (0..$#aobjarrays) {
	  @retvals = ($aobjarrays[$i]{rule_def},$aobjarrays[$i]{type});
	  #print @retvals;
	 
	}	

	return @retvals;
}



#########################################################################
sub checkerror {
    my %ehash = @_;
    if ( $ehash{ERROR} ) {
        $lh->log_print( $ehash{ERROR} );
        return 1;
    }
}


##
#here's an example of realllly bad coding.  I've coppied the above section, which was alreay bad enough.
#the code below is called when a non timeout rule is called.  Now all 4 sloppy huge secions of code have
#to be maintained.
#

sub notimesection {

####################################################################
		#ANALYSIS RULE SECTION 

		if ($type =~ /ANALYSIS/) {
				my @eval;
				my $retval; 
			

			my $analysis_rule_id;
			my ($sv_name,$error_string,$cc_alias,$host);
			
			$analysis_rule_id = $ruleid;
			if ($debug) {$lh->log_print("Recieved Analysis Id: $analysis_rule_id")}
			@eval = &getarule($analysis_rule_id);
			
			unless ($eval[0]) {
				$lh->log_print("RECIEVED A REQUEST: $_ TO EXECUTE A INVALID RULE ID = $analysis_rule_id");
				goto ENDARULE;
			}
			
			if ($debug) {$lh->log_print("Analysis Rule type = $eval[1]")}
			#if ($eval[1] =~ "Perl") { #don't check type
				#print $eval[0];
				$retval = 0; #set retval to zero - in case the analysis rule does not
				if ($debug) {$lh->log_print("Analysis Rule def = $eval[0]")}
				eval $eval[0];
				if ($@) { 
					$lh->log_print("EVALED ERROR FOR ANALISIS ID: $analysis_rule_id =".$@);
					$@ =~ s/\'/\'\'/g; #pad error string, pad single quotes which screw up sql (compare this to 20 lines of vb ;)
					my $error = substr($@,0, 195);
					vadmin::data1::udateaoerr($datasession,$debug,$lh,$analysis_rule_id,"WARNING: Partial analysis Rule execution Error: $error");
					vadmin::data1::sendsysmsg($datasession,$debug,$lh,'ARULEUPD'); #send a message to update the error hash
					
					my $datestring = &getdatestring;
		 			my @args = (undef,undef,"WARNING: Partial analysis Rule execution Error: $error",undef,"RULERROR","ANALYSIS_RULE",$datestring,undef,undef,$_,undef);					
					eval{$client->call('errorinsert',@args)};
					if ($@) {$lh->log_print("ERROR: Could not report event! :\t $@")}
						
					goto ENDARULE;
					#return 0; #don't go on to insert a matching error...cause the script failed
			}
				print "RETVAL = $retval\n";


			unless ($retval) {
				my $href;
				my @arrayofdefs = vadmin::data1::insert_arule_error($datasession,$debug,$lh,$analysis_rule_id);
				$lh->log_print("rule id: $1 returned a false value - Searching for associated Error Definitoins and sending an event.");
				
				unless (@arrayofdefs) {$lh->log_print("WARNING!!! ANALYSIS RULE ID = $analysis_rule_id SHOULD GENERATE AND EVENT BASED ON RETURNING A FALSE VALUE.  HOWEVER, IT HAS NO ERROR DEFINITION ASSOCIATED WITH IT SO IT WILL NOT GENERATE AN EVENT.")};

				for $href (@arrayofdefs) { #submit a error event for each error definition for this analysis rule
					my %Data = %$href;  #derefrenced hash to process from array of hashes

					if ($debug) {$lh->log_print("Inserted an error event based on rule id: $analysis_rule_id returning a false value - err definition = ")};
					
					$error_string = substr($error_string,0,253); #otherwise sv_string could exceed size for errorevent field
					my $datestring = &getdatestring();
				    
					if ($debug) {$lh->log_print("Inserting an error event based on rule id: $analysis_rule_id returning a false value")};
				
					my @args = ($Data{sf_elmnt_id},$sv_name,$error_string,$Data{ev_level},$Data{ev_type},$Data{ev_sub_type},$datestring,$Data{error_defs_id},$cc_alias,$host,$analysis_rule_id);
					
					$lh->log_print("ERROR EVENT ARGUMENTS for violated rule id  $analysis_rule_id  : @args");
										
					eval{$client->call('errorinsert',@args)};
					if ($@) {$lh->log_print("ERROR: Could not report event! :\t $@")}
				}


			} 
		
			#evaluate retval.... if true do nothing, if false enter error event
			#if $@ mark inactive and update returned errors in analysis_rule
			ENDARULE:
				print  "SUCESSREQ: $analysis_rule_id\n";

			

		}
		#print $session "RETVAL = $retval ERRORS = $@ \n";
	##

####################################################################
#COLLECTOR RULE SECTION
	
	
		if ($type =~ /COLLECTOR RULE/) {
				my @eval;
				my $retval; 
				chomp;
			my $datestring;

			my $collectorid = $ruleid;;  #better save $1 for later
			@eval = &getstatrule($collectorid);

			unless ($eval[0]) {
				#defect = 10/7/2003 - rules were being violated because they were inactive but had been routed to the evalrunner
				$lh->log_print("RECIEVED A REQUEST: $_ TO EXECUTE A INVALID RULE ID = $collectorid");
				goto ENDCOLLECTOR;
			}
			

					print "evaled perl string = $eval[0]\n";
					eval $eval[0];
					if ($@) { 
						$lh->log_print("EVALED ERROR FOR COLLECTOR ID: $collectorid =".$@);
						$@ =~ s/\'/\'\'/g; #pad error string, pad single quotes which screw up sql (compare this to 20 lines of vb ;)
						my $error = substr($@,0, 195);
						vadmin::data1::updatestaterr($datasession,$debug,$lh,$collectorid,"WARNING: Partial Collector Rule execution Error: $error");
						vadmin::data1::sendsysmsg($datasession,$debug,$lh,'STATUPD'); #send a message to update the error hash


						my $datestring = &getdatestring;
		 				my @args = (undef,undef,"WARNING: Partial Collector Rule execution Error: $error",undef,"RULERROR","COLLECTOR",$datestring,undef,undef,$_,undef);					
						eval{$client->call('errorinsert',@args)};
						if ($@) {$lh->log_print("ERROR: Could not report event! :\t $@")}
						
						
						
						goto ENDCOLLECTOR;  #don't go on to insert a matching error...cause the script failed
						}
					#$retval is a variable returned from the collector defined by the user
					print "RETVAL = $retval\n";
						

				
				
				my $datestring = &getdatestring();

				
				if ($retval > 0) {
					vadmin::data1::insert_statval($datasession,$debug,$lh,$retval,$datestring,$collectorid);
				}
				
				ENDCOLLECTOR:	
				print  "SUCESSREQ - COLLECTOR: $collectorid\n";
					

		}



}



