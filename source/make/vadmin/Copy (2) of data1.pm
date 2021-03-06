#!e:\perl\bin\perl -w

package vadmin::data1;

use strict;
use Win32::ODBC;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(odbcsess 
insertpid 
deletepidbyid
deletepidbytid
deletepidbypid
getstringerrors 
inserterrorevent 
getinitvars 
getinterval
componentprocess 
deletecomps 
taskprocess 
getlogdir 
getcompsmonitored 
insertappmsg
getpids
updatepid
updatesrvrstatus
getlocalappservers
getevents
getaevent
getnoterules
getschedules
getadmins
getcomserver
getreactions
sendsysmsg
updatesysmsg
deletesysmsg
insert_react_hist
getlsmxmsg
getrulename
updateeventstatus
getroutehost
getsyssrvrmgrcmds
getaoh
udateaoerr
insert_arule_error
insert_statval
updatestaterr
gethashrecord
getarrayofvals
alterdateformat
odbcsesspool
gethosts
);


#################################################################################
#SUB odbcsess starts a ODBC session
#################################################################################

sub odbcsess{ #odbcsess($DNS,$UID,$PWD)
	my $db;
	my $rethash;
	my ($debug, $lh,$DNS,$UID,$PWD) = @_;
	#print  "@_ \n";
	if (!($db=new Win32::ODBC("DSN=$DNS;UID=$UID;PWD=$PWD;"))) {
    $lh->log_print("Error connecting to $DNS");
	$lh->fail("Error: " . Win32::ODBC::Error());
	}
    else {
     return $db;
  }
}#end odbcsess


sub odbcsesspool{ #odbcsess($DNS,$UID,$PWD)
	my $db;
	my $rethash;
	my ($debug, $lh,$DNS,$UID,$PWD) = @_;
	#print  "@_ \n";
	if (!($db=new Win32::ODBC("DSN=$DNS;UID=$UID;PWD=$PWD;"))) {
    $lh->log_print("COULD NOT CREATE A SHARED DATA CONNECTION - MAKE SURE THAT ALL DATA SOURCES HAVE AN EXISTING ODBC DATASOURCE ON THE CENTRAL SERVER AND CORRECT PASSWEORD. Error connecting to $DNS");
	$lh->log_print("Error: " . Win32::ODBC::Error());
	}
    else {
     return $db;
  }
}#end odbcsess



#################################################################################
#SUB getinitvars - Executes sql statement with SQL session  - returns init vals
#################################################################################
 
sub getinitvars{#takes service name as input,data session,server_id
my ($rethash,$entid);
my ($db, $debug, $lh, $service_name,%Data,$SqlStatement,%initvars) = @_;

$SqlStatement = "SELECT t2.sft_elmnt_id \"enterprise_id\", t2.name \"enterprise\", t1.sft_elmnt_id \"appserver_id\", t1.type, t1.name \"appserver_name\", t1.host, t1.installdir \"installdir\", t1.service_name, t1.parent_elmnt_id FROM sft_elmnt t1,sft_elmnt t2 where  t1.type = 'appserver' and t2.type = 'enterprise' and t1.name = '$service_name'";
if ($debug) {$lh->log_print($SqlStatement)}
if ($db->Sql($SqlStatement)) {
   $lh->log_print("SQL failed - on init var get = $SqlStatement");
	  my ($ErrNum, $ErrText, $ErrConn) = $db->Error();
      $lh->log_print("SQL ERRORS: $ErrNum $ErrText $ErrConn");
}
else  {
      while($db->FetchRow()) {
      %Data = $db->DataHash();
		 $initvars{server_id} = $Data{"appserver_id"};
         $initvars{server_name} = $Data{"appserver_name"};
		 $initvars{enterprise}= $Data{"enterprise"};
		 $initvars{serverpath} = $Data{"installdir"};#path to siebel server
		 $entid = $Data{"enterprise_id"};
		 $initvars{appserver_id} = $Data{"appserver_id"};
      }

	my $hashkey;
	foreach  $hashkey (keys %Data) {
		print "RETRUNDED DATA HASH = $hashkey = $Data{$hashkey}\n"; 
	}


	}
$SqlStatement = "select elmnt_key \"elmnt_key\",elmnt_value \"elmnt_value\" from sft_elmnt_comp where sft_elmnt_id = $entid";
if ($db->Sql($SqlStatement)) {
   $lh->log_print("SQL ERROR: failed = $SqlStatement");
   	  my ($ErrNum, $ErrText, $ErrConn) = $db->Error();
      $lh->log_print("SQL ERRORS: $ErrNum $ErrText $ErrConn");
   $rethash =   "Error: " . $db->Error();
   return  $rethash;
   # add some function to try to reinitialize db session
}
else  {
      while($db->FetchRow()) {
      %Data = $db->DataHash();
		 $initvars{$Data{"elmnt_key"}} = $Data{"elmnt_value"};		
      }
	}
   return %initvars;
}# exec sql


#################################################################################
#SUB getinterval()
#################################################################################
 
sub getinterval{#no args, returns global timer operation
my $rethash;
my ($db,%Data,$SqlStatement,$retval) = @_;

$SqlStatement = "SELECT t1.message FROM system_msg t1 where t1.type = 1";
if ($db->Sql($SqlStatement)) {
		print("SQL  failed = $SqlStatement");
	  my ($ErrNum, $ErrText, $ErrConn) = $db->Error();
		print("ERRORS: $ErrNum $ErrText $ErrConn");
	  return 0;
   # add some function to try to reinitialize db session
}
else  {
      while($db->FetchRow()) {
      %Data = $db->DataHash();
         $retval = $Data{"message"};
	  }
	}
   return $retval;
}# exec sql

#################################################################################
#SUB componentprocess()
#################################################################################
 
sub componentprocess{#db session, $debug,@componentlist)
my $rethash;
my ($db,$debug,$lh,$server_id,@fl,%Data,$SqlStatement,$retval) = @_;

#############
#insert
############

my %insertcheck = &gethashrecord($db,$debug,$lh,"select cc_alias \"cc_alias\" from monitored_comps where cc_alias = \'$fl[1]\' and sft_elmnt_id = '$server_id'");

unless ($insertcheck{cc_alias}) {

	my $incvar = &keyincr($db,$debug,$lh,"monitored_comps","monitored_comps_id");
	$SqlStatement = "insert into monitored_comps (monitored_comps_id,sft_elmnt_id,sv_name,cc_alias,cc_name,ct_alias,cg_name,cc_runmode,cp_disp_run_state,cp_num_run,cp_max_tas,cp_actv_mt,cp_max_mts,cp_start_time,cp_end_time,cp_status) values ($incvar,$server_id,\'$fl[0]\',\'$fl[1]\' , \'$fl[2]\', \'$fl[3]\', \'$fl[4]\',\'$fl[5]\', \'$fl[6]\',\'$fl[7]\',\'$fl[8]\',\'$fl[9]\', \'$fl[10]\', \'$fl[11]\',\'$fl[12]\',\'$fl[13]\')";
	&execsql($db,$debug,$lh,$SqlStatement);
}
#############
#update
############

		$SqlStatement = "update monitored_comps set cc_alias = \'$fl[1]\' ,cc_name = \'$fl[2]\',ct_alias = \'$fl[3]\',cg_name= \'$fl[4]\',cc_runmode = \'$fl[5]\',cp_disp_run_state = \'$fl[6]\',cp_num_run = \'$fl[7]\',cp_max_tas = \'$fl[8]\',cp_actv_mt = \'$fl[9]\',cp_max_mts = \'$fl[10]\',cp_start_time = \'$fl[11]\',cp_end_time = \'$fl[12]\',cp_status = \'$fl[13]\' where cc_alias = \'$fl[1]\' and sft_elmnt_id = '$server_id'" ;
		&execsql($db,$debug,$lh,$SqlStatement);


}


#################################################################################
#SUB taskprocess()
#################################################################################
 
sub taskprocess{#db session, @componentlist)
my $rethash;
my ($db,$debug,$lh,$server_id,@fl,%Data,$SqlStatement,$retval) = @_;


#############
#insert
############

my %insertcheck = &gethashrecord($db,$debug,$lh,"select tk_taskid \"tk_taskid\" from server_task where tk_taskid = \'$fl[2]\' and sft_elmnt_id  = '$server_id'");

unless ($insertcheck{tk_taskid}) {

	my $incvar = &keyincr($db,$debug,$lh,"server_task","server_task_id");
	$SqlStatement = " insert into server_task (server_task_id,sft_elmnt_id,sv_name,cc_alias,tk_taskid,tk_pid,tk_disp_runstate,cc_runmode,tk_start_time,tk_end_time,tk_status,cg_alias,tk_parent_t,cc_incarn_no,tk_label,tk_tasktype) values ($incvar ,$server_id, \'$fl[0]\',\'$fl[1]\' , \'$fl[2]\', \'$fl[3]\', \'$fl[4]\',\'$fl[5]\', \'$fl[6]\',\'$fl[7]\',\'$fl[8]\',\'$fl[9]\','$fl[10]','$fl[11]','$fl[12]','$fl[13]')";
	&execsql($db,$debug,$lh,$SqlStatement);		
}

#############
#update
############
	$SqlStatement = "update server_task set tk_pid = \'$fl[3]\' ,tk_disp_runstate = \'$fl[4]\',cc_runmode = \'$fl[5]\',tk_start_time= \'$fl[6]\',tk_end_time = \'$fl[7]\',tk_status = \'$fl[8]\',cg_alias = \'$fl[9]\' where tk_taskid = \'$fl[2]\' and sv_name = \'$fl[0]\' and sft_elmnt_id = $server_id";
	&execsql($db,$debug,$lh,$SqlStatement);

}



#################################################################################
#SUB deletecomps()
#################################################################################

sub deletecomps {#db session, $server_id)

my ($db,$debug,$lh,$sv_name,$SqlStatement) = @_;

	$SqlStatement = "delete from monitored_comps where sv_name = '$sv_name'";
	&execsql($db,$debug,$lh,$SqlStatement);

}



#################################################################################
#SUB deleteasks()
#################################################################################

sub deletetasks {#db session, $server_id)
my $rethash;
my ($db,$debug,$lh,$server_id, $SqlStatement,$retval) = @_;

	$SqlStatement = "delete from server_task where sft_elmnt_id = '$server_id'";
	&execsql($db,$debug,$lh,$SqlStatement);
}


#################################################################################
#SUB getlogdir
#################################################################################
 
sub getlogdir{#takes service name as input,data session,server_id
my $rethash;
my ($service_name,$debug,$db,$lh,%Data,$SqlStatement,%initvars) = @_;

$SqlStatement = "SELECT t1.appserver_id, t1.sv_name,t1.installdir from app_server t1 where  t1.sv_name = '$service_name'";
if ($debug) {$lh->log_print("GET LOG DIR SQL = $SqlStatement")}
if ($db->Sql($SqlStatement)) {
   $lh->log_print ("SQL ERROR:  Failed SQL = $SqlStatement ");
	$lh->log_print($SqlStatement);
   $lh->log_print($db->Error());
   $rethash =   "Error: " . $db->Error();
   return  $rethash;
   # add some function to try to reinitialize db session
}
else  {
      while($db->FetchRow()) {
      %Data = $db->DataHash();
		 $initvars{servername} = $Data{"sv_name"};	
		 $initvars{server_id} = $Data{"appserver_id"};
		 $initvars{serverpath} = $Data{"installdir"};				#path to siebel server 			
      }
	}
   return %initvars;
}# exec sql


sub getcompsmonitored{
	my (%Data,$rethash);
	my @complist;
	my ($db,$debug,$lh,$server_id) = @_;
	#log_analyze  = 'Y' and (may need to replace this... )
	my $SqlStatement = "SELECT cc_alias \"cc_alias\" from components t1 where  t1.sft_elmnt_id  in (select t2.parent_elmnt_id from sft_elmnt t2 where t2.parent_elmnt_id = t1.sft_elmnt_id and t2.sft_elmnt_id = '$server_id')"; #and t2.sft_elmnt_id = '$server_id'
		if ($debug) {$lh->log_print("GET COMPS MONITORED SQL = $SqlStatement")}
		if ($db->Sql($SqlStatement)) {
		   $lh->log_print ("SQL ERROR:  Failed SQL = $SqlStatement");
		   $lh->log_print($SqlStatement);
		   $lh->log_print($db->Error());
		   $rethash =   "Error: " . $db->Error();
		   return  $rethash;
		   # add some function to try to reinitialize db session
		}
		else  {
			  while($db->FetchRow()) {
			  %Data = $db->DataHash();
			   push @complist,$Data{cc_alias};
			  }
			}
		   return @complist;
		}# exec sql

###################################################################################################

sub getstringerrors{
	my (%Data,$rethash);
	my @stringlist;
	my ($db,$debug,$lh,$comp,$server_id) = @_;
	my $SqlStatement = "select t1.search_string \"search_string\",t1.error_defs_id \"error_defs_id\",t1.ev_level \"ev_level\",t1.ev_type \"ev_type\",t1.ev_sub_type \"ev_sub_type\" from sft_error_defs t1, comp_errdef t2, components t3 where t1.error_defs_id = t2.error_defs_id and  t2.components_id =  t3.components_id  and t3.cc_alias like \'$comp\'";
		
		if ($debug) {$lh->log_print("GET STRING ERRORS SQL = $SqlStatement")}
		if ($db->Sql($SqlStatement)) {
		   $lh->log_print ("SQL ERROR: Failed SQL = $SqlStatement");
		   $lh->log_print($SqlStatement);
		   $lh->log_print($db->Error());
		   $rethash =   "Error: " . $db->Error();
		   return  $rethash;
		   # add some function to try to reinitialize db session
		}
		else  {
			  while($db->FetchRow()) {
			  %Data = $db->DataHash();
			   push @stringlist,[$Data{search_string},$Data{error_defs_id},$Data{ev_level},$Data{ev_type}];
			  }
			}
			foreach  (@stringlist) {
				#print "data.pm error string = $_\n";
			}
		   return @stringlist;
		}# exec sql

#################################################################################
#SUB insert system log message
#################################################################################

sub insertappmsg{#db session, @componentlist)
my $rethash;
my ($db,$debug,$lh,$server,@fl,%Data,$SqlStatement,$retval) = @_;

	sub sysmsgincr {
	my $rethash;
	$SqlStatement = "select max(appserver_events_id) + 1 \"increment\" from appserver_events";
	if ($db->Sql($SqlStatement)) {
	   $lh->log_print("SQL taskprocess increment failed.\n");
	   $lh->log_print($db->Error());
	   $rethash =   "Error: " . $db->Error();
	   #$server_id = 1;
	}
	else  {
		  while($db->FetchRow()) {
		  %Data = $db->DataHash();
			 $rethash = $Data{"increment"};
			 unless ($rethash) {
				 $rethash++;
			 }
		  }
		}
	return $rethash;
	}
#############
#insert
############
	my $incvar = &sysmsgincr;
	$SqlStatement = "insert into appserver_events (appserver_events_id,sv_name,event_type,sub_type,event_level,event_time,event_string) values ($incvar,\'$server\',\'$fl[0]\',\'$fl[1]\',\'$fl[2]\',\'$fl[3]\',\'$fl[4]\')";
	if ($debug) {$lh->log_print("insertappmsg statement = $SqlStatement");}
	if ($db->Sql($SqlStatement)) {
	   $lh->log_print("SQL insertappmsg failed.\n");
	   $lh->log_print($db->Error());
	   $rethash =   "Error: " . $db->Error();
	   return  $rethash;
	   # add some function to try to reinitialize db session
	}  
}

#################################################################################
#SUB inserterrorevent ($db,$debug,$lh,$server,$event_string,$usr_event_level,$usr_event_type,$error_defs_id)
#################################################################################

sub inserterrorevent{#db session, @componentlist)
my $rethash;
my ($db,$debug,$lh,$sft_elmnt_id,$server,$event_string,$usr_event_level,$usr_event_type,$usr_event_sub_type,$event_time,$error_defs_id,$cc_alias,$host,$analysis_rule_id,%Data,$SqlStatement,$retval) = @_;


my $incvar = &erroridincr;
	$SqlStatement = "insert into errorevent (errorevent_id,sft_elmnt_id,sv_name,event_string,event_level,type,event_sub_type,event_time,error_defs_id,cc_alias,host,analysis_rule_id) values ('$incvar','$sft_elmnt_id','$server','$event_string','$usr_event_level','$usr_event_type','$usr_event_sub_type','$event_time','$error_defs_id','$cc_alias','$host','$analysis_rule_id')";
	if ($debug) {$lh->log_print("inserterrorevent statement = $SqlStatement")}
	if ($db->Sql($SqlStatement)) {
	   $lh->log_print("SQL insert error event failed.\n");
	  my ($ErrNum, $ErrText, $ErrConn) = $db->Error();
      $lh->log_print("ERRORS: $ErrNum $ErrText $ErrConn");
	   $rethash =   "Error: " . $db->Error();
	   return  $rethash;
	   # add some function to try to reinitialize db session
	}  

	return $incvar;

	sub erroridincr {
	my $rethash;
	$SqlStatement = "select max(errorevent_id) + 1 \"increment\" from errorevent";
	if ($db->Sql($SqlStatement)) {
	   $lh->log_print("SQL inserterrorevent increment failed.\n");
	   my ($ErrNum, $ErrText, $ErrConn) = $db->Error();
       $lh->log_print("ERRORS: $ErrNum $ErrText $ErrConn");
	   $rethash =   "Error: " . $db->Error();
	   #$server_id = 1;
	}
	else  {
		  while($db->FetchRow()) {
		  %Data = $db->DataHash();
			 $rethash = $Data{"increment"};
			 unless ($rethash) {
				 $rethash++;
			 }
		  }
		}
	return $rethash;
	}
#############
#insert
############
	
}

#################################################################################
#SUB insert pid ($db,$debug,$lh,$sv_name,$task_id,$pid,$cc_alias,$cc_name,$host)
#################################################################################

sub insertpid{#db session, @componentlist)
my $rethash;
my ($db,$debug,$lh,$sv_name,$task_id,$pid,$cc_alias,$cc_name,$host,$sft_elmnt_id,%Data,$SqlStatement,$retval) = @_;

	sub processincr {
	my $rethash;
	$SqlStatement = "select max(process_id) + 1 \"increment\" from processes";
	if ($db->Sql($SqlStatement)) {
	   $lh->log_print("SQL taskprocess increment failed.\n");
	   $lh->log_print($db->Error());
	   $rethash =   "Error: " . $db->Error();
	   #$server_id = 1;
	}
	else  {
		  while($db->FetchRow()) {
		  %Data = $db->DataHash();
			 $rethash = $Data{"increment"};
			 unless ($rethash) {
				 $rethash++;
			 }
		  }
		}
	return $rethash;
	}
#############
#insert
############
	my $incvar = &processincr;

my %insertcheck = &gethashrecord($db,$debug,$lh,"select pid \"pid\" from processes where pid = '$pid' and sv_name = '$sv_name'");

unless ($insertcheck{pid}) {

	$SqlStatement = "insert into processes (process_id,sv_name,task_id,pid,cc_alias,cc_name,host,sft_elmnt_id) values ($incvar,'$sv_name','$task_id','$pid','$cc_alias','$cc_name','$host','$sft_elmnt_id')";
	if ($debug) {$lh->log_print("insertpid insert statement = $SqlStatement")}
	if ($db->Sql($SqlStatement)) {
	   $lh->log_print("SQL insertpid failed =  $SqlStatement\n");
	   $lh->log_print($db->Error());
	   $rethash =   "Error: " . $db->Error();
	   return  $rethash;
	   # add some function to try to reinitialize db session
	}  
}

}


#################################################################################
#SUB delete pid ($db,$debug,$lh,$task_id,$pid,$cc_alias,$cc_name,$host)
#################################################################################

sub deletepidbypid{#db session, @componentlist)
my $rethash;
my ($db,$debug,$lh,$pid,$host,$SqlStatement,$retval) = @_;

	$SqlStatement = "delete from processes where pid = '$pid' and host = '$host'";
	if ($debug) {$lh->log_print("deletepidbyid statement = $SqlStatement")};
	if ($db->Sql($SqlStatement)) {
	   $lh->log_print("SQL delete pid failed.\n");
	   $lh->log_print($db->Error());
	   $rethash =   "Error: " . $db->Error();
	   return  $rethash;
	   # add some function to try to reinitialize db session
	}  
}


#################################################################################
#SUB delete pid ($db,$debug,$lh,$task_id,$pid,$cc_alias,$cc_name,$host)
#################################################################################

sub deletepidbyid{#db session, @componentlist)
my $rethash;
my ($db,$debug,$lh,$sft_elmnt_id,$SqlStatement,$retval) = @_;

	$SqlStatement = "delete from processes where sft_elmnt_id = '$sft_elmnt_id' ";
	if ($debug) {$lh->log_print("deletepidbyid statement = $SqlStatement")};
	if ($db->Sql($SqlStatement)) {
	   $lh->log_print("SQL delete pid failed.\n");
	   $lh->log_print($db->Error());
	   $rethash =   "Error: " . $db->Error();
	   return  $rethash;
	   # add some function to try to reinitialize db session
	}  
}


#################################################################################
#SUB delete pidbytid ($db,$debug,$lh,$task_id,$pid,$cc_alias,$cc_name,$host)
#################################################################################

sub deletepidbytid{#db session, @componentlist)
my $rethash;
my ($db,$debug,$lh,$task_id,$sft_elmnt_id,$SqlStatement,$retval) = @_;

	$SqlStatement = "delete from processes where task_id = '$task_id' and sft_elmnt_id = '$sft_elmnt_id'";
	if ($debug) {$lh->log_print("deletepidbytid statement = $SqlStatement");
	if ($db->Sql($SqlStatement)) {
	   $lh->log_print("SQL delete pid failed.\n")};
	   $lh->log_print($db->Error());
	   $rethash =   "Error: " . $db->Error();
	   return  $rethash;
	   # add some function to try to reinitialize db session
	}  
}

#################################################################################
#SUB update pid ($db,$debug,$lh,$task_id,$pid,$cc_alias,$cc_name,$host)
#################################################################################

sub updatepid{#db session, @componentlist)
my $rethash;
my ($SqlStatement,$retval);
my ($db,$debug,$lh,$host,$pid,$process,$cpu,$cpu_time,$kernel_time,$user_time,$memory,$pagefaults,$virtualmem,$priority,$threads) = @_;

	$SqlStatement = "update processes set process = '$process',cpu = '$cpu', cpu_time = '$cpu_time', kernel_time = '$kernel_time',user_time = '$user_time', memory = '$memory', pagefaults = '$pagefaults', virtualmem = '$virtualmem', priority = '$priority', threads = '$threads'  where  pid = '$pid' and  host = '$host'";
	if ($debug) {$lh->log_print("update pid update statement = $SqlStatement");}
	if ($db->Sql($SqlStatement)) {
	   $lh->log_print("SQL updatepid failed =  $SqlStatement");
	   $lh->log_print($db->Error());
	   $rethash =   "Error: " . $db->Error();
	   return  $rethash;
	   # add some function to try to reinitialize db session
	}  
}


#################################################################################
#SUB updatesrvrstatus ($db,$debug,$lh,$host,$srvr,$status)
#################################################################################

sub updatesrvrstatus{#db session, @componentlist)
my $rethash;
my ($SqlStatement,$retval);
my ($db,$debug,$lh,$server_id,$status) = @_;

	$SqlStatement = "update sft_elmnt set status = '$status' where sft_elmnt_id = $server_id ";
	if ($debug) {$lh->log_print("update pid server status statement = $SqlStatement")}
	&execsql($db,$debug,$lh,$SqlStatement);

	
}

#################################################################################
#SUB updateeventstatus ($db,$debug,$lh,$eventid)
#################################################################################

sub updateeventstatus{#db session, @componentlist)
my $rethash;
my ($SqlStatement,$retval);
my ($db,$debug,$lh,$eventid) = @_;

	$SqlStatement = "update errorevent set processed = 'Y' where errorevent_id = '$eventid'";
	if ($debug) {$lh->log_print("updateeventstutus  Sql = $SqlStatement")}
	&execsql($db,$debug,$lh,$SqlStatement);

	#pass in a delete property - if true delete the event
	
}


#################################################################################
#SUB getlocalappservers ($db,$debug,$lh,$host,$srvr,$status)
#################################################################################

sub getlocalappservers{#db session, @componentlist)
my @apps;
my %Data1;
my ($SqlStatement,$retval);
my ($db,$debug,$lh,$host) = @_;

	$SqlStatement =  "select * from sft_elmnt where type = 'appserver' and host = '$host'";
	if ($debug) {$lh->log_print("localapp sql = $SqlStatement")}
	
		if ($db = &execsql($db,$debug,$lh,$SqlStatement)) {
		
			if ($debug) {$lh->log_print("after exec sql")}
				
				
				  while($db->FetchRow()) {
					  if ($debug) {$lh->log_print("in the fetchwhile")}
				  
				 
					  if ($debug) {$lh->log_print("in the eval")}
				  %Data1 = $db->DataHash();
				  
				  
				  if ($@) {$lh->log_print($@)}
					   if ($debug) {$lh->log_print("after db datatahash")}
					 push @apps, {%Data1};	
						if ($debug) {$lh->log_print("after push")}
					}
				
				

		}

	if ($debug) {$lh->log_print("before return")}
	return @apps;
}



#################################################################################
#SUB getevents ($db,$debug,$lh) - array of hashes of unprocessed events
#################################################################################

sub getevents{#db session, @componentlist)
my @events;
my %Data;
my ($SqlStatement,$retval);
my ($db,$debug,$lh) = @_;

	$SqlStatement =  "select processed \"processed\", sv_name \"sv_name\", type \"type\", errorevent_id \"errorevent_id\", sft_elmnt_id \"sft_elmnt_id\",event_sub_type \"event_sub_type\", event_level \"event_level\", event_time \"event_time\", event_string \"event_string\"  from errorevent where processed is NULL or processed != 'Y'";
	if ($debug) {$lh->log_print("getevents sql = $SqlStatement")}
	
	if ($db = &execsql($db,$debug,$lh,$SqlStatement)) {
	
		  while($db->FetchRow()) {
		  %Data = $db->DataHash();
		  push @events, {%Data};
		}
		
	}

	return @events;
}

#################################################################################
#SUB getaevent ($db,$debug,$lh,$eventid) - array of hashes of unprocessed events
#################################################################################

sub getaevent{#db session, @componentlist)
my @events;
my %Data;
my ($SqlStatement,$retval);
my ($db,$debug,$lh,$eventid) = @_;

	$SqlStatement =  "select processed \"processed\", sv_name \"sv_name\", type \"type\", errorevent_id \"errorevent_id\", sft_elmnt_id \"sft_elmnt_id\",event_sub_type \"event_sub_type\", event_level \"event_level\", event_time \"event_time\", event_string \"event_string\"  from errorevent where errorevent_id = '$eventid'";
	
	if ($debug) {$lh->log_print("getevents sql = $SqlStatement")}
	
	if ($db = &execsql($db,$debug,$lh,$SqlStatement)) {
	
		  while($db->FetchRow()) {
		  %Data = $db->DataHash();
		  push @events, {%Data};   #returning a hash of arrays cause the deprecated getevents returned a hash of arrays and i'm too lazy to change it.
		}
		
	}

	return @events;
}



#################################################################################
#SUB getschedules ($db,$debug,$lh,$date) - array of hashes of unprocessed events
#################################################################################

sub getschedules{#db session, @componentlist)
my @schedules;
my %Data;
my ($SqlStatement,$retval);
my ($db,$debug,$lh,$day) = @_;

	$SqlStatement =  "select hour_start \"hour_start\", hour_end \"hour_end\",minute_start \"minute_start\", minute_end \"minute_end\", schedule_every \"schedule_every\", schedule_id \"schedule_id\" from schedule where schedule_every = 'Y' or every_day = 'Y' or $day = 'Y'";
	if ($debug) {$lh->log_print("getschedules sql = $SqlStatement")}
	
	if ($db = &execsql($db,$debug,$lh,$SqlStatement)) {
	
		  while($db->FetchRow()) {
		  %Data = $db->DataHash();
		  push @schedules, {%Data};
		}
		
	}

	return @schedules;
}



#################################################################################
#SUB getnotifications ($db,$debug,$lh) -array of hashes of notification rules 
#################################################################################

sub getnoterules{#db session, @componentlist)
my @noterules;
my %Data;
my ($SqlStatement,$retval);
my ($db,$debug,$lh) = @_;

	$SqlStatement =  "select notify_all  \"N\", name \"name\", note_rule_id \"noteruleid\", type \"type\", ev_sft_elmnt_id \"ev_sft_elmnt_id\", ev_event_sub_type \"ev_event_sub_type\", ev_event_level \"ev_event_level\", ev_event_time \"ev_event_time\",ev_event_string \"ev_event_string\" from notification_rule where active = 'Y'";
	if ($debug) {$lh->log_print("get rules sql = $SqlStatement")}
	
	if ($db = &execsql($db,$debug,$lh,$SqlStatement)) {
	
		  while($db->FetchRow()) {
		  %Data = $db->DataHash();
		  push @noterules, {%Data};
		}
		
	}

	return @noterules;
}


#################################################################################
#SUB getreactions ($db,$debug,$lh,$note_rule_id) -array of hashes reaction ids, and hosts to route to 
#################################################################################

sub getreactions{#db session, @componentlist)
my @reactions;
my %Data;
my ($SqlStatement,$retval);
my ($db,$debug,$lh,$note_rule_id) = @_;

	$SqlStatement =  "select t1.type \"type\", t1.sv_name \"sv_name\", t1.name \"name\",rule_def \"rule_def\",t1.reaction_id \"reaction_id\",t1.host_specific \"host_specific\" from reaction t1,notification_reaction t2, notification_rule t3 where t1.active = 'Y' and t1.reaction_id = t2.reaction_id and t2.note_rule_id = t3.note_rule_id and t3.note_rule_id = '$note_rule_id'";
	if ($debug) {$lh->log_print("get reactions sql = $SqlStatement")}
	
	if ($db = &execsql($db,$debug,$lh,$SqlStatement)) {
	
		  while($db->FetchRow()) {
		  %Data = $db->DataHash();
		  push @reactions, {%Data};
		}
		
	}

	return @reactions;
}



#################################################################################
#SUB getadmins ($db,$debug,$lh) -array of hashes of admins
#################################################################################

sub getadmins{#db session, @componentlist)
my @admins;
my %Data;
my @events;
my ($SqlStatement,$retval);
my ($db,$debug,$lh,$sched_id) = @_;

	$SqlStatement =  "select administrators_id \"administrators_id\", email \"email\" from administrators where schedule_id = $sched_id";
	if ($debug) {$lh->log_print("get admins sql = $SqlStatement")}
	
	if ($db = &execsql($db,$debug,$lh,$SqlStatement)) {
	
		  while($db->FetchRow()) {
		  %Data = $db->DataHash();
		  push @admins, {%Data};   #returning a hash of arrays cause the deprecated getevents returned a hash of arrays and i'm too lazy to change it.
		
		  #push @admins, {%Data};
		}
		
	}

	return @admins;
}



#################################################################################
#SUB getcomserver ($db,$debug,$lh,$adminid) -array of hashes of admins
#################################################################################

sub getcomserver{#db session, @componentlist)
  my @comservers;
  my %Data;
  my ($SqlStatement,$retval);
  my ($db,$debug,$lh,$adminid) = @_;
  
  	$SqlStatement =  "select type \"type\", smtp_server \"smtp_server\" from comunicationserver t1,com_admin t2 where t1.com_server_id = t2.com_server_id and t2.administrators_id = $adminid";
  	if ($debug) {$lh->log_print("getcomserver sql = $SqlStatement")}
  	
  	if ($db = &execsql($db,$debug,$lh,$SqlStatement)) {
  		
  		  while($db->FetchRow()) {
  		  %Data = $db->DataHash();
  		   push @comservers, {%Data};
  		}
  		
  	}
  
  	return @comservers;
}


#################################################################################
#SUB getruledef ($db,$debug,$lh,$adminid) -array of hashes of admins
#################################################################################

sub getruledef{#db session, @componentlist)
my ($ruledef,$retrule);
my %Data;
my ($SqlStatement,$retval);
my ($db,$debug,$reaction_id) = @_;

	$SqlStatement =  "select rule_def \"rule_def\" from reaction where reaction_id = '$reaction_id'"; 
	if ($debug) {print("getruledef sql = $SqlStatement")};
	
	if ($db->Sql($SqlStatement)) {
	  print("SQL  failed = $SqlStatement");
	  my ($ErrNum, $ErrText, $ErrConn) = $db->Error();
      print("ERRORS: $ErrNum $ErrText $ErrConn");;
	}
	else  {
		  while($db->FetchRow()) {
		  %Data = $db->DataHash();
			 $retrule = $Data{"rule_def"};

		  }
		
	return $retrule;
	}
}

#################################################################################
#SUB getrulename ($db,$debug,$lh,$adminid) -array of hashes of admins
#################################################################################

sub getrulename{#db session, @componentlist)
my ($ruledef,$retrule);
my %Data;
my ($SqlStatement,$retval);
my ($db,$debug,$lh,$reaction_id) = @_;

	$SqlStatement =  "select name \"name\" from reaction where reaction_id = '$reaction_id'"; 
	if ($debug) {$lh->log_print("getrulename sql = $SqlStatement")}
	
	if ($db->Sql($SqlStatement)) {
	  	  $lh->log_print("SQL  failed = $SqlStatement");
		  my ($ErrNum, $ErrText, $ErrConn) = $db->Error();
		  $lh->log_print("ERRORS: $ErrNum $ErrText $ErrConn");;
	}
	else  {
		  while($db->FetchRow()) {
		  %Data = $db->DataHash();
			 $retrule = $Data{"name"};

		  }
		
	return $retrule;
	}
}


#################################################################################
#SUB getroutehost ($db,$debug,$lh,$errorevent_id) 
#################################################################################

sub getroutehost{#db session, @componentlist)
my ($host);
my %Data;
my ($SqlStatement,$retval);
my ($db,$debug,$lh,$errorevent_id) = @_;

	$SqlStatement =  "select t1.host \"host\" from sft_elmnt t1,errorevent t2 where t2.sft_elmnt_id  = t1.sft_elmnt_id  and t2.errorevent_id = '$errorevent_id'"; 
	if ($debug) {$lh->log_print("getroutehost sql = $SqlStatement")}
	
	if ($db->Sql($SqlStatement)) {
	  	  $lh->log_print("SQL  failed = $SqlStatement");
		  my ($ErrNum, $ErrText, $ErrConn) = $db->Error();
		  $lh->log_print("ERRORS: $ErrNum $ErrText $ErrConn");;
	}
	else  {
		  while($db->FetchRow()) {
		  %Data = $db->DataHash();
			 $host = $Data{"host"};
		  }
		
	return $host;
	}
}



#################################################################################
#SUB sendsysmsg(db session, $debug,$type,$message,$host,$appserver)
#################################################################################
 
sub sendsysmsg{#db session, $debug,$type,$message,$host,$appserver)

my ($db,$debug,$lh,$type,$message,$host,$appserver) = @_;
my ($SqlStatement);


#############
#insert
############
	my $incvar = &keyincr($db,$debug,$lh,"system_msg","system_msg_id");
	$SqlStatement = "insert into system_msg (system_msg_id,type,message,host,app_server) values ($incvar,'$type','$message','$host','$appserver')";
	if ($debug) {$lh->log_print("sendsystemmsg sql = $SqlStatement")};
	&execsql($db,$debug,$lh,$SqlStatement);

}


#################################################################################
#SUB deletesystemmsg()
#################################################################################
 
sub deletsysmsg{#db session, $debug,$system_msg_id)

my ($db,$debug,$lh,$system_msg_id) = @_;
my ($SqlStatement);


#############
#delete
############
	
	$SqlStatement = "delete from system_msg where system_msg_id = $system_msg_id";

	if ($debug) {$lh->log_print("deletesysmsg sql = $SqlStatement")};
	&execsql($db,$debug,$lh,$SqlStatement);

}






#################################################################################
#SUB updatesysmsg()
#################################################################################
 
sub updatesysmsg{#db session, $debug,$system_msg_id)

my ($db,$debug,$lh,$system_msg_id,$message,$processesed) = @_;
my ($SqlStatement);


#############
#update
############
	
	$SqlStatement = "update system_msg set message  = '$message', processesed = '$processesed' where system_msg_id = $system_msg_id";

	if ($debug) {$lh->log_print("updatesysmsg sql = $SqlStatement")};
	&execsql($db,$debug,$lh,$SqlStatement);

}


#################################################################################
#SUB insert_react_hist(db session, $debug,$lh,$reaction_id,$errorevent_id,$error,$sucess,$execution_time,$host)
#################################################################################
 
sub insert_react_hist{#db session, $debug,$lh,$reaction_id,$errorevent_id,$error,$sucess,$execution_time,$host)

my ($db,$debug,$lh, $reaction_id,$errorevent_id,$error,$sucess,$execution_time,$host) = @_;
my ($SqlStatement);


#############
#insert
############
	my $incvar = &keyincr($db,$debug,$lh,"react_hist","react_hist_id");
	$SqlStatement = "insert into react_hist(reaction_id,errorevent_id,error,sucess,execution_time,host) values ('$reaction_id','$errorevent_id','$error','$sucess','$execution_time','$host')";

	if ($debug) {$lh->log_print("sendsystemmsg sql = $SqlStatement")};
	&execsql($db,$debug,$lh,$SqlStatement);

}



#################################################################################
#SUB getpids list (#db session, $debug,$lh,$host)
#################################################################################

sub getpids{#db session, $debug,$lh,$host)
my @retlist;
my($SqlStatement,%Data);
my ($db,$debug,$lh,$host) = @_;

	$SqlStatement = "select pid \"pid\" from processes where host = '$host'";
	if ($debug) {$lh->log_print("getpids  statement = $SqlStatement");}
	if ($db->Sql($SqlStatement)) {
	   $lh->log_print("SQL getpids  failed.\n");
	   $lh->log_print($db->Error());
	   #$rethash =   "Error: " . $db->Error();
	   return  0;
	   # add some function to try to reinitialize db session
	}  else  {
		  while($db->FetchRow()) {
		  %Data = $db->DataHash();
			 push @retlist, $Data{pid}; 	 
		  }
		}
	return @retlist;
	}



#################################################################################
#SUB getlsmxmsg ($db,$debug,$lh,$adminid) -array of hashes of admins
#################################################################################

sub getlsmxmsg{#db session, @componentlist)
my @sysmessages;
my %Data;
my ($SqlStatement,$retval);
my ($db,$debug,$lh,$host) = @_;

	$SqlStatement =  "select * from system_msg where type = 2 or type = 4 and host = '$host'";
	if ($debug) {$lh->log_print("getlsmxmsg sql = $SqlStatement")}
	
	if ($db = &execsql($db,$debug,$lh,$SqlStatement)) {
		
		  while($db->FetchRow()) {
		  %Data = $db->DataHash();
		  push @sysmessages, {%Data};
		}	
	}
	return @sysmessages;
}



#################################################################################
#SUB getccxmsg ($db,$debug,$lh,$adminid) -routed message to execute on the central server
#################################################################################

sub getccxmsg{#db session, @componentlist)
my @sysmessages;
my %Data;
my ($SqlStatement,$retval);
my ($db,$debug,$lh,$host) = @_;

	$SqlStatement =  "select message \"message\", system_msg_id \"system_msg_id\" from system_msg where type = 2 or type = 4 and host = '$host'";
	if ($debug) {$lh->log_print("getlsmxmsg sql = $SqlStatement")}
	
	if ($db = &execsql($db,$debug,$lh,$SqlStatement)) {
		
		  while($db->FetchRow()) {
		  %Data = $db->DataHash();
		  push @sysmessages, {%Data};
		}	
	}
	return @sysmessages;
}







#################################################################################
#SUB getsyssrvrmgrcmds ($db,$debug,$lh,$adminid) -array of hashes of admins
#################################################################################

sub getsyssrvrmgrcmds{#db session, @componentlist)
my @sysmessages;
my %Data;
my ($SqlStatement,$retval);
my ($db,$debug,$lh,$appserver) = @_;

	$SqlStatement =  "select message \"message\", system_msg_id \"system_msg_id\" from system_msg where type = 3 and app_server = '$appserver'";
	if ($debug) {$lh->log_print("getsyssrvrmgrcmds sql = $SqlStatement")}
	
	if ($db = &execsql($db,$debug,$lh,$SqlStatement)) {
		
		  while($db->FetchRow()) {
		  %Data = $db->DataHash();
		  push @sysmessages, {%Data};
		}	
	}
	return @sysmessages;
}



#################################################################################
#SUB alterdateformat($db,$debug,$lh,$SqlStatement) -alters current oracle session defalut date formate
#################################################################################

sub alterdateformat{#db session, @componentlist)
my @aoh;
my %Data;
my ($db,$debug,$lh,$SqlStatement) = @_;

	$SqlStatement = "alter session set NLS_DATE_FORMAT = 'mm/dd/yyyy hh24:mi:ss'";
	if ($debug) {$lh->log_print("getaoh sql = $SqlStatement")}

	if (&execsql($db,$debug,$lh,$SqlStatement)) {
		$lh->log_print("SUCESSFULLY SET THE DEFAULT DATE FORMAT TO 'mm/dd/yyyy hh24:mi:ss'");
		}
		

}


#################################################################################
#SUB getaoh($db,$debug,$lh,$SqlStatement) -array of
#################################################################################

sub getaoh{#db session, @componentlist)
my @aoh;
my %Data;
my ($db,$debug,$lh,$SqlStatement) = @_;

	if ($debug) {$lh->log_print("getaoh sql = $SqlStatement")}
	
	if (&execsql($db,$debug,$lh,$SqlStatement)) {
		#print "EXEC SQL RETURNED TRUE\n";
		  while($db->FetchRow()) {
		  %Data = $db->DataHash();
		  push @aoh, {%Data};
		  #print $Data{name};
		}
		
	}

	return @aoh;
}


#################################################################################
#SUB getaoh($db,$debug,$lh,$SqlStatement) -array of
#################################################################################

sub gethosts{#db session, @componentlist)
my @hosts;
my %Data;
my ($db,$debug,$lh) = @_;

my $SqlStatement = "select hostname \"hostname\" from host";
	if ($debug) {$lh->log_print("getaoh sql = $SqlStatement")}
	
	if (&execsql($db,$debug,$lh,$SqlStatement)) {
		print "EXEC SQL RETURNED TRUE\n";
		  while($db->FetchRow()) {
		  %Data = $db->DataHash();
		  print "HOSTNAME CHECKER = $Data{hostname}\n";
		  
		  push @hosts, $Data{"hostname"};
		  #print $Data{name};
		}
		
	}

	return @hosts;
}




#################################################################################
#SUB trimstatvals($db,$debug,$lh,$SqlStatement) -array of
#################################################################################

sub trimstatvals{#db session, @componentlist)
my @aoh;
my %Data;
my ($db,$debug,$lh,$collectorid) = @_;

my $SqlStatement = "select max_records \"max_records\" from collector where collector_id = $collectorid";
my %collector = gethashrecord($db,$debug,$lh,$SqlStatement);
my $maxrecord = $collector{max_records}  || 1000; #defalt max to 1000
 
 $SqlStatement = "select stat_vals_id \"stat_vals_id\" from stat_vals where collector_id = $collectorid order by stat_vals_id DESC";

my $counter;
my $lastrecord;
	if ($debug) {$lh->log_print("getstatvals sql = $SqlStatement")}
	
	if (&execsql($db,$debug,$lh,$SqlStatement)) {
		#print "EXEC SQL RETURNED TRUE\n";
		 while($db->FetchRow()) {
		  %Data = $db->DataHash();
		  $counter++;
			if ($counter > $maxrecord) {
				#set lastrecord var to the first stat_vals_id that is greater than > max allowable recs
				unless ($lastrecord) {
					$lastrecord = $Data{stat_vals_id};
				}
			}

		}
		
	}

	#delete from statvals where stat_vals < stat_vals_id that has been identified as last in the maxrecord series
	if ($lastrecord) {
		$SqlStatement = "delete from stat_vals where stat_vals_id < $lastrecord and collector_id = $collectorid";
		if ($debug) {$lh->log_print("Trim Statvals sql = $SqlStatement")}
		&execsql($db,$debug,$lh,$SqlStatement);

	}
	

}





#################################################################################++
#SUB getaoh($db,$debug,$lh,$SqlStatement) -array of
#################################################################################

sub getarrayofvals{#db session, @componentlist)
my @aov;
my %Data;
my ($db,$SqlStatement) = @_;

	
	if (&execsqlnodebug($db,$SqlStatement)) {

		  while($db->FetchRow()) {
		  %Data = $db->DataHash();
		  push @aov, $Data{val};

		}
		
	}

	return @aov;
}






#################################################################################
#SUB gethashrecord($db,$debug,$lh,$SqlStatement) - return hash record
#################################################################################

sub gethashrecord{#db session, @componentlist)
my @aoh;
my %Data;
my ($db,$debug,$lh,$SqlStatement) = @_;

	if ($debug) {$lh->log_print("gethashrec sql = $SqlStatement")}
	
	if (&execsql($db,$debug,$lh,$SqlStatement)) {
		#print "EXEC SQL RETURNED TRUE\n";
		  while($db->FetchRow()) {
		  %Data = $db->DataHash();
		}	
	}
	return %Data; #if select reutrns multiple rows, the last row will be returned
}


#################################################################################
#SUB updateaoerr($db,$debug,$lh,$aid,$error) -array of
#################################################################################

sub udateaoerr{#db session, @componentlist)
my @aoh;
my %Data;
my ($db,$debug,$lh,$aid,$error) = @_;
my $SqlStatement;

	$SqlStatement = "update analysis_rule set error = '$error', active = 'N' where analysis_rule_id = '$aid'";
	if ($debug) {$lh->log_print("getaoh sql = $SqlStatement")}
	
	if ($db = &execsql($db,$debug,$lh,$SqlStatement)) {
		
		  while($db->FetchRow()) {
		  %Data = $db->DataHash();
		  push @aoh, {%Data};
		  #print $Data{name};
		}
		
		
	} else {return 0;}

	return @aoh;
}


#################################################################################
#SUB updatestaterr($db,$debug,$lh,$aid,$error) -array of
#################################################################################

sub updatestaterr{#db session, @componentlist)
my @aoh;
my %Data;
my ($db,$debug,$lh,$cid,$error) = @_;
my $SqlStatement;

	$SqlStatement = "update collector set error = '$error', active = 'N' where collector_id = '$cid'";
	if ($debug) {$lh->log_print("get collector sql = $SqlStatement")}
	
	if ($db = &execsql($db,$debug,$lh,$SqlStatement)) {
		
		  while($db->FetchRow()) {
		  %Data = $db->DataHash();
		  push @aoh, {%Data};
		  #print $Data{name};
		}
		
		
	} else {return 0;}

	return @aoh;
}



#################################################################################
#SUB insert_arule_error($db,$debug,$lh,$aid) 
#################################################################################

sub insert_arule_error{#db session, @componentlist)
my @aoh;
my %Data;
my ($db,$debug,$lh,$arule_id) = @_;
my $SqlStatement;

#{evt_sf_elmnt_id},$sv_name,$sv_string,$Data{ev_level},$Data{ev_type},$Data{ev_sub_type},$datestring,$Data{error_defs_id},$cc_alias,$host);
	$SqlStatement = "select t1.search_string \"search_string\", t1.sf_elmnt_id \"sf_elmnt_id\", t1.ev_level \"ev_level\", t1.ev_sub_type \"ev_sub_type\", t1.ev_type \"ev_type\", t1.error_defs_id \"error_defs_id\" from sft_error_defs t1, analysis_errdef t2 where t1.error_defs_id = t2.error_defs_id and t2.analysis_rule_id = '$arule_id'";
	if ($debug) {$lh->log_print("insert arule error = $SqlStatement")}
	
	if ($db = &execsql($db,$debug,$lh,$SqlStatement)) {
		
		  while($db->FetchRow()) {
		  %Data = $db->DataHash();
		  push @aoh, {%Data};
		}
		
		return @aoh;
	} else {return 0;}
	
	#my $id = keyincr($db,$debug,$lh,'errorevent','errorevent_id');
	#$SqlStatement =  "insert into errorevent(errorevent_id,type,event_sub_type,event_level,event_string,status,cc_alias,sv_name,host,sft_elmnt_id) values ('$id','$Data{evt_type}','$Data{evt_event_sub_type}','$Data{evt_event_level}','$Data{evt_event_string}','$Data{evt_status}','$Data{evt_cc_alias}','$Data{sv_name}','$Data{evt_host}','$Data{evt_sft_elmnt_id}')";
	#	if ($debug) {$lh->log_print("insert keyincr = $SqlStatement")}
		
	#	if ($db = &execsql($db,$debug,$lh,$SqlStatement)) {

#		} else {return 0;}


}


#################################################################################
#SUB insert_statval($db,$debug,$lh,$aid) 
#################################################################################

sub insert_statval{#db session, @componentlist)
my @aoh;
my %Data;
my ($db,$debug,$lh,$val,$datetime,$collectorid) = @_;
my $SqlStatement;


	my $id = keyincr($db,$debug,$lh,'stat_vals','stat_vals_id');
	$SqlStatement = "insert into stat_vals(stat_vals_id,val,time_stmp,collector_id) values ('$id','$val','$datetime','$collectorid')";
	if ($debug) {$lh->log_print("insert stat_val sql = $SqlStatement")}
	 
	 &execsql($db,$debug,$lh,$SqlStatement);
	# trimstatvals($db,$debug,$lh,$collectorid);

}


#################################################################################
#insternal subs
#################################################################################



	sub keyincr {
	
	my ($db,$debug,$lh,$table,$primary_key,%Data,$SqlStatement,$retval) = @_;
	my $rethash;
	$SqlStatement = "select max($primary_key) + 1 \"increment\" from $table";
	if ($db->Sql($SqlStatement)) {
	   $lh->log_print("SQL $table increment failed");
	   $lh->log_print($SqlStatement);
	   $lh->log_print($db->Error());
	   $rethash =   "Error: " . $db->Error();
	   #$server_id = 1;
	}
	else  {
		  while($db->FetchRow()) {
		  %Data = $db->DataHash();
			 $rethash = $Data{"increment"};
			 unless ($rethash) {
				 $rethash++;
			 }
		  }
		}
	return $rethash;
	}


sub execsql {

	my ($db,$debug,$lh,$SqlStatement) = @_;
	#if ($debug) {$lh->log_print("sql = $SqlStatement\n")};

		if ( $db->Sql($SqlStatement)) {
		  $lh->log_print("SQL  failed = $SqlStatement");
		  my ($ErrNum, $ErrText, $ErrConn) = $db->Error();
		  $lh->log_print("ERRORS: $ErrNum $ErrText $ErrConn");
		  return 0;

		   # add some function to try to reinitialize db session
		}  else {return $db}; 
	
}

sub execsqlnodebug {

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
