#!e:\perl\bin\perl -w

package vadmin::data;

use strict;
use Win32::ODBC;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(odbcsess 
insertpid 
deletepid 
getstringerrors 
inserterrorevent 
getinitvars 
getinterval 
componentprocess 
deltecomps 
taskprocess 
getlogdir 
getcompsmonitored 
insertappmsg
getpids
updatepid
updatesrvrstatus
);


#################################################################################
#SUB odbcsess starts a ODBC session
#################################################################################

sub odbcsess{ #odbcsess($DNS,$UID,$PWD)
	my $db;
	my $rethash;
	my ($DNS,$UID,$PWD) = @_;
	#print  "@_ \n";
	if (!($db=new Win32::ODBC("DSN=$DNS;UID=$UID;PWD=$PWD;"))) {
    #print  "Error connecting to $DNS\n";
	$rethash = "Error: Win32::ODBC::Error()";
	#print $rethash;
    return  $rethash;
	}
    else {
     return $db;
  }
}#end odbcsess


#################################################################################
#SUB getinitvars - Executes sql statement with SQL session  - returns init vals
#################################################################################
 
sub getinitvars{#takes service name as input,data session,server_id
my $rethash;
my ($service_name,$db,%Data,$SqlStatement,%initvars) = @_;

$SqlStatement = "SELECT t1.appserver_id, t1.sv_name ,t1.installdir, t2.enterprise, t2.login, t2.password FROM app_server t1, enterprises t2 where t1.enterprise_id = t2.enterprise_id and  t1.sv_name = '$service_name'";
if ($db->Sql($SqlStatement)) {
   print  "SQL failed.\n";
   $rethash =   "Error: " . $db->Error();
   return  $rethash;
   # add some function to try to reinitialize db session
}
else  {
      while($db->FetchRow()) {
      %Data = $db->DataHash();
		 $initvars{server_id} = $Data{"appserver_id"};
         $initvars{server_name} = $Data{"sv_name"};
		 $initvars{enterprise}= $Data{"enterprise"};
		 $initvars{password} = $Data{"password"};							#username
		 $initvars{username} = $Data{"login"};								#db password
		 $initvars{serverpath} = $Data{"installdir"};				#path to siebel server 			
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
   print  "SQL failed.\n";
   $rethash =   "Error: " . $db->Error();
   return  $rethash;
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
my ($db,$debug,$lh,@fl,%Data,$SqlStatement,$retval) = @_;

	sub compincrement {
	my $rethash;
	$SqlStatement = "select max(monitored_comps_id) + 1 \"increment\" from monitored_comps";
	if ($db->Sql($SqlStatement)) {
	   if ($debug) {$lh->log_print("SQL componentprocess increment failed.\n");
	   $lh->log_print($SqlStatement)};
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
	my $incvar = &compincrement;
	$SqlStatement = "if not exists(select cc_alias from monitored_comps where cc_alias = \'$fl[1]\' and sv_name = \'$fl[0]\') insert monitored_comps (monitored_comps_id,sv_name,cc_alias,cc_name,ct_alias,cg_name,cc_runmode,cp_disp_run_state,cp_num_run,cp_max_tas,cp_actv_mt,cp_max_mts,cp_start_time,cp_end_time,cp_status) values ($incvar ,\'$fl[0]\',\'$fl[1]\' , \'$fl[2]\', \'$fl[3]\', \'$fl[4]\',\'$fl[5]\', \'$fl[6]\',\'$fl[7]\',\'$fl[8]\',\'$fl[9]\', \'$fl[10]\', \'$fl[11]\',\'$fl[12]\',\'$fl[13]\')";
	if ($debug) {$lh->log_print("component process insert = $SqlStatement\n")};
	if ($db->Sql($SqlStatement)) {
	  $lh->log_print("SQL component process insert failed.\n");
	   $lh->log_print($db->Error());
	   $rethash =   "Error: " . $db->Error();
	   return  $rethash;
	   # add some function to try to reinitialize db session
	}  


#############
#update
############
	$SqlStatement = "update monitored_comps set cc_alias = \'$fl[1]\' ,cc_name = \'$fl[2]\',ct_alias = \'$fl[3]\',cg_name= \'$fl[4]\',cc_runmode = \'$fl[5]\',cp_disp_run_state = \'$fl[6]\',cp_num_run = \'$fl[7]\',cp_max_tas = \'$fl[8]\',cp_actv_mt = \'$fl[9]\',cp_max_mts = \'$fl[10]\',cp_start_time = \'$fl[11]\',cp_end_time = \'$fl[12]\',cp_status = \'$fl[13]\' where cc_alias = \'$fl[1]\' and sv_name = \'$fl[0]\'" ;
	if ($debug) {$lh->log_print("$SqlStatement\n")};
	if ($db->Sql($SqlStatement)) {
	   $lh->log_print ("SQL componentprocess update failed.\n");
		$lh->log_print($db->Error());
	   $rethash =   "Error: " . $db->Error();
	   return  $rethash;
	   # add some function to try to reinitialize db session
	}     

}

#################################################################################
#SUB deletecomps()
#################################################################################

sub deletecomps {#db session, $server_id)
my $rethash;
my ($db,$server_id,$lh,@fl,%Data,$SqlStatement,$retval) = @_;

	$SqlStatement = "delete from monitored_comps where sv_name = \'$server_id\'";
	if ($db->Sql($SqlStatement)) {
	   print("$SqlStatement\n");
	   print ("SQL delete failed.\n");
	   print($db->Error());
	   $rethash =   "Error: " . $db->Error();
	}
	
	else {print("component delete sucessful\n");
	print "$SqlStatement\n";}
}

#################################################################################
#SUB taskprocess()
#################################################################################
 
sub taskprocess{#db session, @componentlist)
my $rethash;
my ($db,$debug,$lh,@fl,%Data,$SqlStatement,$retval) = @_;

	sub taskincrement {
	my $rethash;
	$SqlStatement = "select max(server_task_id) + 1 \"increment\" from server_task";
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
	my $incvar = &taskincrement;
	$SqlStatement = "if not exists(select tk_taskid from server_task where tk_taskid = \'$fl[2]\' and sv_name = \'$fl[0]\') insert server_task (server_task_id,sv_name,cc_alias,tk_taskid,tk_pid,tk_disp_runstate,cc_runmode,tk_start_time,tk_end_time,tk_status,cg_alias) values ($incvar ,\'$fl[0]\',\'$fl[1]\' , \'$fl[2]\', \'$fl[3]\', \'$fl[4]\',\'$fl[5]\', \'$fl[6]\',\'$fl[7]\',\'$fl[8]\',\'$fl[9]\')";
	if ($debug) {print "taskprocess insert statement = $SqlStatement\n";}
	if ($db->Sql($SqlStatement)) {
	   $lh->log_print("SQL taskprocess insert failed.\n");
	   $lh->log_print($db->Error());
	   $rethash =   "Error: " . $db->Error();
	   return  $rethash;
	   # add some function to try to reinitialize db session
	}  


#############
#update
############
	$SqlStatement = "update server_task set tk_pid = \'$fl[3]\' ,tk_disp_runstate = \'$fl[4]\',cc_runmode = \'$fl[5]\',tk_start_time= \'$fl[6]\',tk_end_time = \'$fl[7]\',tk_status = \'$fl[8]\',cg_alias = \'$fl[9]\' where tk_taskid = \'$fl[2]\' and sv_name = \'$fl[0]\'";
	if ($debug) {$lh->log_print("processtask sqlstatement = $SqlStatement\n")}
	if ($db->Sql($SqlStatement)) {
	   $lh->log_print("SQL processtask update failed.\n");
	   $lh->log_print($db->Error());
	   $rethash =   "Error: " . $db->Error();
	   return  $rethash;
	   # add some function to try to reinitialize db session
	}     

}


#################################################################################
#SUB deleteasks()
#################################################################################

sub deletetasks {#db session, $server_id)
my $rethash;
my ($db,$server_id,$lh,@fl,%Data,$SqlStatement,$retval) = @_;

	$SqlStatement = "delete from server_task where sv_name = \'$server_id\'";
	if ($db->Sql($SqlStatement)) {
	   $lh->log_print ("SQL task delete failed.\n");
	   $lh->log_print($db->Error());
	   $rethash =   "Error: " . $db->Error();
	}
	else {print("component delete sucessful\n")}
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
   $lh->log_print ("SQL failed.\n");
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
	my ($db,$debug,$lh) = @_;
	my $SqlStatement = "SELECT cc_alias from components where log_analyze  = \'Y\'"; 
		
		if ($debug) {$lh->log_print("GET COMPS MONITORED SQL = $SqlStatement")}
		if ($db->Sql($SqlStatement)) {
		   $lh->log_print ("SQL failed.\n");
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


sub getstringerrors{
	my (%Data,$rethash);
	my @stringlist;
	my ($db,$debug,$lh,$comp) = @_;
	my $SqlStatement = "select t1.search_string,t1.error_defs_id,t1.template,t1.anded,t1.type,t1.errorlevel,t1.eventtypename,t1.errortime,t1.evt_error_level,t1.evt_type from error_defs t1, comp_errdef t2 where t1.error_defs_id = t2.error_defs_id and t2.cc_alias like \'$comp\'";
		
		if ($debug) {$lh->log_print("GET STRING ERRORS SQL = $SqlStatement")}
		if ($db->Sql($SqlStatement)) {
		   $lh->log_print ("SQL failed.\n");
		   $lh->log_print($SqlStatement);
		   $lh->log_print($db->Error());
		   $rethash =   "Error: " . $db->Error();
		   return  $rethash;
		   # add some function to try to reinitialize db session
		}
		else  {
			  while($db->FetchRow()) {
			  %Data = $db->DataHash();
			   push @stringlist,[$Data{type},$Data{eventtypename},$Data{errorlevel},$Data{errortime},$Data{search_string},$Data{template},$Data{anded},$Data{evt_error_level},$Data{evt_type},$Data{error_defs_id}];
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
	$SqlStatement = "insert appserver_events (appserver_events_id,sv_name,event_type,sub_type,event_level,event_time,event_string) values ($incvar,\'$server\',\'$fl[0]\',\'$fl[1]\',\'$fl[2]\',\'$fl[3]\',\'$fl[4]\')";
	if ($debug) {print "taskprocess insert statement = $SqlStatement\n";}
	if ($db->Sql($SqlStatement)) {
	   $lh->log_print("SQL taskprocess insert failed.\n");
	   $lh->log_print($db->Error());
	   $rethash =   "Error: " . $db->Error();
	   return  $rethash;
	   # add some function to try to reinitialize db session
	}  
}

#################################################################################
#SUB insert errorevent ($db,$debug,$lh,$server,$event_string,$usr_event_level,$usr_event_type,$error_defs_id)
#################################################################################

sub inserterrorevent{#db session, @componentlist)
my $rethash;
my ($db,$debug,$lh,$server,$event_string,$usr_event_level,$usr_event_type,$error_defs_id,%Data,$SqlStatement,$retval) = @_;

	sub erroridincr {
	my $rethash;
	$SqlStatement = "select max(errorevent_id) + 1 \"increment\" from errorevent";
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
	my $incvar = &erroridincr;
	$SqlStatement = "insert errorevent (errorevent_id,sv_name,event_string,usr_event_level,usr_event_type,error_defs_id) values ($incvar,\'$server\',\'$event_string\',\'$usr_event_level\',\'$usr_event_type\',\'$error_defs_id\')";
	if ($debug) {print "taskprocess insert statement = $SqlStatement\n";}
	if ($db->Sql($SqlStatement)) {
	   $lh->log_print("SQL taskprocess insert failed.\n");
	   $lh->log_print($db->Error());
	   $rethash =   "Error: " . $db->Error();
	   return  $rethash;
	   # add some function to try to reinitialize db session
	}  
}

#################################################################################
#SUB insert pid ($db,$debug,$lh,$sv_name,$task_id,$pid,$cc_alias,$cc_name,$host)
#################################################################################

sub insertpid{#db session, @componentlist)
my $rethash;
my ($db,$debug,$lh,$sv_name,$task_id,$pid,$cc_alias,$cc_name,$host,%Data,$SqlStatement,$retval) = @_;

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
	$SqlStatement = "if not exists(select pid from processes where pid = '$pid' and sv_name = '$sv_name')insert processes (process_id,sv_name,task_id,pid,cc_alias,cc_name,host) values ($incvar,'$sv_name','$task_id','$pid','$cc_alias','$cc_name','$host')";
	if ($debug) {$lh->log_print("taskprocess insert statement = $SqlStatement")}
	if ($db->Sql($SqlStatement)) {
	   $lh->log_print("SQL taskprocess insert failed.\n");
	   $lh->log_print($db->Error());
	   $rethash =   "Error: " . $db->Error();
	   return  $rethash;
	   # add some function to try to reinitialize db session
	}  
}

#################################################################################
#SUB delete pid ($db,$debug,$lh,$task_id,$pid,$cc_alias,$cc_name,$host)
#################################################################################

sub deletepid{#db session, @componentlist)
my $rethash;
my ($db,$debug,$lh,$sv_name,$task_id,$pid,$host,$SqlStatement,$retval) = @_;

	$SqlStatement = "delete from processes where task_id = '$task_id' or pid = '$pid' or sv_name = '$sv_name' and host = '$host'";
	if ($debug) {print "taskprocess insert statement = $SqlStatement\n";}
	if ($db->Sql($SqlStatement)) {
	   $lh->log_print("SQL taskprocess insert failed.\n");
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
my ($db,$debug,$lh,$host,$pid,$process,$cpu,$cpu_time,$memory,$pagefaults,$virtualmem,$priority,$threads) = @_;

	$SqlStatement = "update processes set process = '$process',cpu = '$cpu', cpu_time = '$cpu_time', memory = '$memory', pagefaults = '$pagefaults', virtualmem = '$virtualmem', priority = '$priority', threads = '$threads'  where  pid = '$pid' and  host = '$host'";
	if ($debug) {print "update pid update statement = $SqlStatement\n";}
	if ($db->Sql($SqlStatement)) {
	   $lh->log_print("SQL taskprocess insert failed.\n");
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
my ($db,$debug,$lh,$host,$srvr,$status) = @_;

	$SqlStatement = "update app_server set app_server.status = '$status' from app_server, host where app_server.host_id =  host.host_id and app_server.sv_name = '$srvr' and  host.hostname = '$host'";
	if ($debug) {print "update pid update statement = $SqlStatement\n";}
	if ($db->Sql($SqlStatement)) {
	   $lh->log_print("SQL updatessvrrstatus insert failed.\n");
	   $lh->log_print("Error: " . $db->Error() . $SqlStatement);
	   $rethash =   "Error: " . $db->Error() . $SqlStatement;
	   return  $rethash;
	   # add some function to try to reinitialize db session
	}  
}





#################################################################################
#SUB getpids list (#db session, $debug,$lh,$host)
#################################################################################

sub getpids{#db session, $debug,$lh,$host)
my @retlist;
my($SqlStatement,%Data);
my ($db,$debug,$lh,$host) = @_;

	$SqlStatement = "select * from processes where host = '$host'";
	if ($debug) {print "taskprocess insert statement = $SqlStatement\n";}
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

