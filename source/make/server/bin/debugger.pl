# file: tcp_echo_serv2.pl
# Figure 5.4: The reverse echo server, using IO::Socket

# usage: tcp_echo_serv2.pl [port]

use strict;
use Win32::ODBC;
use Win32;
use Date::Calc;
use Win32::OLE;
use Time::Local;
use Net::Ping;
use Win32::OLE qw( in );
use Win32::OLE::Const;
use vadmin::data1;
use Log::Logger;
use Cwd;
use Cwd 'abs_path';	    # aka realpath()
use LWP::UserAgent;
use LWP::Protocol::http;



my $curdir = cwd;
print "using dir $curdir/lib\n";
use lib "$curdir/lib"; #does not give an error on wrong path.....


use vars('$datasession','$lh','$debug');
$main::datasession;
$main::lh;
$main::debug;

$debug = 1;

unless (@ARGV > 3) {
print "Incorrect Arguments.  Try debugger.exe \$type \$id \$odbcname \$uid \$password \n";
print "@ARGV\n";
my $end = <STDIN>;
exit;
}


my $type	= $ARGV[0];
my $id		= $ARGV[1];
my $vodbc	= $ARGV[2];
my $uid		= $ARGV[3];
my $pwd		= $ARGV[4];

#print "odbc = $vodbc, uid = $uid, pwd = $pwd, type = $type, id = $id\n";


$lh = new Log::Logger "debugger.log" || new Log::Logger "debugger.log";    # global log file


###########################################################################

my ( $key, %srvmgrvars );

$datasession = odbcsess( $vodbc, $uid, $pwd );


#############################################################################
#start up other data sessions......

my @arrayofdatasources = getaoh($datasession,"select alias \"alias\", name \"name\", username \"username\", password \"password\" from data_source");


my %datasource;  # hash of datasources that will be pre-started 

foreach my $dshash (@arrayofdatasources) {
		my %deref = %$dshash;

		print("Data session connection pooling initializing for Data Source: $deref{alias}"); 
		$datasource{$deref{alias} } = odbcsess($deref{name},$deref{username},$deref{password} );
		print "alias = $deref{alias};\n";
		
	}
	
##############################################################################




####################################################################
#ANALYSIS RULE SECTION 

		if ($type =~ /ANALYSIS/) {
			my ($sv_name,$sv_string,$cc_alias,$host);
			my $analysis_rule_id = $id;
			my $retval;
			my $error_string;


			my %eval = &getarule($analysis_rule_id);
			my $stime = Win32::GetTickCount() ;
			print "####################################################################\n";
			print "EXECUTING ANALYIS RULE WITH DEFINITION:\n";
			print "\n\n$eval{rule_def}\n";

				eval $eval{rule_def};
				if ($@) { 
			print "\n\n\n####################################################################\n";	
			print "ANALYSIS RULE HAS A SYNTAX ERROR.  IF EXECUTED IN NON DEBUG MODE IT WILL BE SET TO INACTIVE:\n";
			print("\n\nERROR: ".$@);
					goto ENDLOOP;

				}
			
			my $etime = Win32::GetTickCount(); 
				if ( $eval{notimeout} !~ 'Y' && ((($etime - $stime) / 1000) > 10) ) {
				print "\n\n\n####################################################################\n";	
				print "ANALYSIS RULE HAS TAKEN GRATER THAN 10 SECONDS TO EXECUTE.  IF EXECUTED IN NON DEBUG MODE IT WILL BE SET TO INACTIVE:\n";
				print("\n\nERROR: ".$@);
					goto ENDLOOP;

				}
			
			print "\n\n\n####################################################################\n";
			print "Below is the returned value.  If it is blank or = 0, a event will be inserted (in non debug mode) based on this rule returning a false value\n";
			print "\nRETVAL = $retval\n";
			print "\$error_string = $error_string\n";
		
				#while loop....
		}
	

####################################################################
#COLLECTOR RULE SECTION
	
	
		if ($type =~ /STAT/) {

			my $collectorid = $type;  #better save $1 for later
			my $retval;
			my $error_string;

			my $stime = Win32::GetTickCount() ;
			print "stime = $stime\n";
			my %eval = &getstatrule($id);
			print "####################################################################\n";
			print "EXECUTING STATISTIC COLLECTOR WITH DEFINITION:\n";
			print "\n\n$eval{rule_def}\n";
			
					eval $eval{rule_def};
					if ($@) { 
			print "\n\n\n####################################################################\n";
			print "STATIC RULE HAS A SYNTAX ERROR.  IF EXECUTED IN NON DEBUG MODE IT WILL BE SET TO INACTIVE:\n";
			
							print("\n\nERROR: ".$@);	
							goto ENDLOOP;
						}
				
				my $etime = Win32::GetTickCount(); 
				print "etime = $etime\n";
				if ( $eval{notimeout} !~ 'Y' && ((($etime - $stime) / 1000) > 10)  ) {
				print "\n\n\n####################################################################\n";	
				print "COLLECTOR HAS TAKEN GRATER THAN 10 SECONDS TO EXECUTE.  IF EXECUTED IN NON DEBUG MODE IT WILL BE SET TO INACTIVE:\n";
				print("\n\nERROR: ".$@);
					goto ENDLOOP;

				}
			

			print "\n\n\n####################################################################\n";
			print "Below is the returned value that would have been inserted for this statistic in non-debug mode.";
			print "\nRETVAL = $retval\n";
			print "\$error_string = $error_string\n";
						
				#while loop

		}

######################################################3
ENDLOOP:
print "\n\n\Press Any Key to Continue......\n";
my $end = <STDIN>;

	
###########################################################################################
sub odbcsess{ #odbcsess($DNS,$UID,$PWD)
	my $db;
	my $rethash;
	my ($DNS,$UID,$PWD) = @_;
	#print  "@_ \n";
	if (!($db=new Win32::ODBC("DSN=$DNS;UID=$UID;PWD=$PWD;"))) {
		print("Error connecting to $DNS");
		print("Error: " . Win32::ODBC::Error());
	}
    else {
     return $db;
  }
}#end odbcsess

#############################################################################################
sub execsql {

	my ($db,$SqlStatement) = @_;

	if ($db->Sql($SqlStatement)) {
	  print("SQL  failed = $SqlStatement");
	  my ($ErrNum, $ErrText, $ErrConn) = $db->Error();
      print("ERRORS: $ErrNum $ErrText $ErrConn");
	  return 0;

	   # add some function to try to reinitialize db session
	}  
	
	else {return $db}; 
}
	

###############################################################################################
sub getarule {
	my $rule_id = shift;
	my $i;	
	my $sql = "select rule_def \"rule_def\", notimeout \"notimeout\" from analysis_rule where analysis_rule_id = $rule_id";
	my $db = execsql($datasession,$sql);
	my %Data;
	
	while($db->FetchRow()) {
		  %Data = $db->DataHash();
	}
	 
	return %Data;
}


############################################################################################
sub getstatrule {
	my $rule_id = shift;
	my $i;	
	my $sql = "select rule_def \"rule_def\", notimeout \"notimeout\" from collector where collector_id = $rule_id";
	my $db = execsql($datasession,$sql);
	my %Data;
	
	while($db->FetchRow()) {
		  %Data = $db->DataHash();
	}
	 
	return %Data;
}


#################################################################################
#SUB getaoh($db,$debug,$lh,$SqlStatement) -array of
#################################################################################

sub getaoh{#db session, @componentlist)
my @aoh;
my %Data;
my ($db,$SqlStatement) = @_;

	eval {
	if (&execsql($db,$SqlStatement)) {
		#print "EXEC SQL RETURNED TRUE\n";
		  while($db->FetchRow()) {
		  %Data = $db->DataHash();
		  push @aoh, {%Data};
		  #print $Data{name};
		}
		
	}
	};
	if ($@) {print "SQL ERROR: $@\n"}

	return @aoh;
}


