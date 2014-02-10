

insert into sft_mng_sys(sft_mng_sys_id,name,type) values (1,'Virtual Administrator 2','VA2')


insert into system_msg (system_msg_id,type,message) values (1,1,60)


insert into sft_error_defs (error_defs_id,name,search_string,ev_level,ev_type,ev_sub_type) values (1,'Component Reached max tasks','','','Components Maxed','')


insert into sft_error_defs (error_defs_id,name,search_string,ev_level,ev_type,ev_sub_type) values (2,'Transaction Backlog','','','Transaction Backlog','')


insert into sft_error_defs (error_defs_id,name,search_string,ev_level,ev_type,ev_sub_type) values (3,'Process or Component exited with Error','Process exited with error','','Process exited with error','')



insert into notification_rule (note_rule_id,name, message,notify_all,active,type,ev_event_sub_type,ev_event_level,ev_event_string) values (1,'Siebel Component Maxed','1 or More Siebel Component has reached Max Tasks','N','Y','Components Maxed','','','')


insert into notification_rule (note_rule_id,name, message,notify_all,active,type,ev_event_sub_type,ev_event_level,ev_event_string) values (2,'Transaction Backlog','Warning!  Transaction Backlog detected','N','Y','Transacton Backlog','','','')


insert into notification_rule (note_rule_id,name, message,notify_all,active,type,ev_event_sub_type,ev_event_level,ev_event_string) values (3,'Siebel Proc Exited with Error!','Siebel Process exited with Error','N','Y','Process exited with error','','','')



/*insert into DEFAULT ANALYSIS RULES*/

insert  into analysis_rule (analysis_rule_id,type,name,description,active,execution_interval,rule_def) values (1,'Perl','Component Reached max tasks','Finds any components that have reached MAX tasks for a component','Y','1','use siebsrvobj;

my $href;     	# refrence to a hash
my @error;   	# list of task errors   

my @allcomps; 	#  array of server task records


my $entobj = siebsrvobj->newobj($datasession,$debug,''siebel'');  	#initialize the enterprise object
@allcomps = $entobj->entcomps();  				#get array of all server tasks


foreach  $href (0..$#allcomps) {  				#loop through the tasks
		
     my $errstring = "COMPONENT: $allcomps[$href]{cc_alias} HAS RUNNING TASKS = $allcomps[$href]{cp_num_run}\n";  	
     print $errstring;  							 	                 #for debugging...

     #look for the string "Exited with error".... if there is an error, add a string to the @error array, which will be emailed...eventually
      if ($allcomps[$href]{cp_num_run} == $allcomps[$href]{cp_max_tas}) {push @error, "WARNING!! THE FOLLOWING COMPONENT HAS MAXED OUT ON ALLOWABLE TASKS: $errstring\n"}		  
  }

if (@error == 0) { #the number of errors == 0, so $retval = 1 
	$retval = 1;
	#errormessage overide = @errors
}')



insert into analysis_rule (analysis_rule_id,type,name,description,active,execution_interval,rule_def) values (2,'Perl','Txn backlog','Checks whether there is a transaction backlog','Y','1440','require sqlanalyze;

my $sql = "select MAX(TXN_ID) \"MAX\" from S_DOCK_TXN_LOG";

my $maxtxn = sqlanalyze->returnsinglevalue($sql, $datasource{siebeldata},"MAX");
print "MAX TXN = $maxtxn\n";

$sql = <<ENDSQL;
select LAST_TXN_NUM "LAST" from S_DOCK_STATUS st, S_NODE n
where st.NODE_ID=n.ROW_ID and 
n.NODE_TYPE_CD="TXNPROC" and
st.LOCAL_FLG="Y" and 
st.TYPE="ROUTE" and
(n.EFF_END_DT IS NULL OR n.EFF_END_DT > getdate())
ENDSQL

my $lastroutedtxn = sqlanalyze->returnsinglevalue($sql, $datasource{siebeldata},"LAST");
print "LAST ROUTED TXN = $lastroutedtxn\n";

unless ($lastroutedtxn > $maxtxn) {$retval = 1}  #if last routed txn is > than the max txn, changes will not be routed to mobile clients
')



/*ATTACH ERROR DEFINITIONS TO ANALYSIS RULES*/


insert into analysis_errdef(analysis_rule_id, error_defs_id) values (1,1)


insert into analysis_errdef(analysis_rule_id, error_defs_id) values (2,2)


/*ATTACH ERROR DEFINITIONS TO ANALYSIS RULES*/

insert into collector(collector_id,type,execution_interval,name,description,active,rule_def) values (1,'Perl','60','Central Server Uptime','Number of hours that Central Server has been running','Y','
$retval = Win32::GetTickCount() / 3600000;')


insert into collector(collector_id,type,execution_interval,name,description,active,rule_def) values (2,'Perl','1440','Number of Opportunities','Number of Opportunities','Y','
use sqlanalyze;
$retval = sqlanalyze->sqlcount("select count(*)  from S_OPTY", $datasource{siebeldata});')


insert into collector(collector_id,type,execution_interval,name,description,active,rule_def) values (3,'Perl','1440','Number of Accounts','Number of Accounts','Y','
use sqlanalyze;
$retval = sqlanalyze->sqlcount("select count(*) from S_ORG_EXT", $datasource{siebeldata});')


insert into collector(collector_id,type,execution_interval,name,description,active,rule_def) values (4,'Perl','1440','Number of Activities','Number of Activities','Y','
use sqlanalyze;
$retval = sqlanalyze->sqlcount("select count(*) from S_EVT_ACT", $datasource{siebeldata});')


insert into collector(collector_id,type,execution_interval,name,description,active,rule_def) values (5,'Perl','1440','Number of Contacts','Number of Contacts','Y','
use sqlanalyze;
$retval = sqlanalyze->sqlcount("select count(*) from S_CONTACT", $datasource{siebeldata});')



insert into collector(collector_id,type,execution_interval,name,description,active,rule_def) values (6,'Perl','10080','Number of Expired Workflow Rules','Count of total number of expired workflow rules - SQL Server','Y','
use sqlanalyze;

my $sql = <<SQLEND;
select count(*) 
from s_escl_rule
where expire_dt is not null and expire_dt <= getdate() 
SQLEND

$retval = sqlanalyze->sqlcount($sql, $datasource{siebeldata});')


insert into collector(collector_id,type,execution_interval,name,description,active,rule_def) values (7,'Perl','1440','S_ESCL_REC backlog','Records in S_ESCL_REQ for expired workflow rules','Y','
use sqlanalyze;

my $sql = <<SQLEND;
select count(*) from s_escl_req where rule_id in (select row_id from s_escl_rule where expire_dt is not null and expire_dt <= getdate()) 
SQLEND

$retval = sqlanalyze->sqlcount($sql, $datasource{siebeldata});
')


insert into collector(collector_id,type,execution_interval,name,description,active,rule_def) values (8,'Perl','1440','Number of Records in S_DOC_TXN_LOG','High value indicates a backlog in Transactions being processed for Mobile Clients','Y','
use sqlanalyze;
my $sql = "select count(*) from S_DOCK_TXN_LOG";
$retval = sqlanalyze->sqlcount($sql, $datasource{siebeldata});
')


insert into collector(collector_id,type,execution_interval,name,description,active,rule_def) values (9,'Perl','1440','Number of DB users -  SQL Server','Number of system process','Y','
use sqlanalyze;

my $sql = "select count(*) from  master.dbo.sysprocesses";

$retval = sqlanalyze->sqlcount($datasession, $datasource{siebeldata});
')


insert into collector(collector_id,type,execution_interval,name,description,active,rule_def) values (10,'Perl','30','Number of DB users -  SQL Server','MB Count of SQL Server size','Y','

require sqlanalyze; 

my $sql = "sp_spaceused"; #sql server stored procedure
my $dbsize = sqlanalyze->returnsinglevalue($sql, $datasource{siebeldata},"database_size");

if ($dbsize =~ /(\d+\.\d+) MB/) {
	$retval = $1;	#$1 is the captured db size from a string
')


insert into collector(collector_id,type,execution_interval,name,description,active,rule_def) values (11,'Perl','10080','DB Size - in MBs - Vadmin21','MB Size of SQL Server  - Vadmin21 db','Y','
require sqlanalyze; 

my $sql = "sp_spaceused"; #sql server stored procedure
my $dbsize = sqlanalyze->returnsinglevalue($sql, $datasession,"database_size"); #$datasession is the active connection to the vadmindb

if ($dbsize =~ /(\d+\.\d+) MB/) {
	$retval = $1;	#$1 is the captured db size from a string
}
')



insert into collector(collector_id,type,execution_interval,name,description,active,rule_def) values (12,'Perl','10800','DB Size - in MBs - SiebelDB','MB Size of SQL Server  - Siebel db','Y','

require sqlanalyze; 

my $sql = "sp_spaceused"; #sql server stored procedure
my $dbsize = sqlanalyze->returnsinglevalue($sql, $datasource{siebeldata},"database_size");

if ($dbsize =~ /(\d+\.\d+) MB/) {
	$retval = $1;	#$1 is the captured db size from a string
}
')


