insert system_msg (system_msg_id,type,message) values (1,1,60)
go
update system_msg set message = 30

insert sft_error_defs (error_defs_id,search_string,name,ev_type) values (1,'Iteration:','Search String - Iteration:','Trivial')
go

insert comp_errdef (components_id,error_defs_id) values (1,1)

insert comp_errdef values (4,1)


insert schedule (schedule_id,schedule_every) values (1,'Y')

insert administrators (administrators_id,first_name,last_name,email,phone,default_admin,schedule_id) values (1,'Charles','Oppenheimer','choppen5@yahoo.com','415-577-3411','Y',1)

insert comunicationserver (com_server_id,smtp_server,name,type) values (1,'localhost','Local SMTP Server','smtp')

insert com_srvr_vals (com_srvr_vals_id,type,elmnt_key,elmnt_value) values (1,'smtp','smtp_server','localhost')
/*insert com_srvr_vals (com_srvr_vals_id,type,elmnt_key,elmnt_value) values (1,'smtp','user_name','choppen5')*/
 

insert com_admin (administrators_id,com_server_id) values (1,1)
insert notification_rule (note_rule_id, message,notify_all,active,name) values (1,"Generic Message - sent with all events",'Y','Y','Notify All - Generic')
update schedule set hour_start = '08', minute_start = '00',hour_end = '17', minute_end = '00'


insert into reaction (reaction_id,type,name,rule_def) values (1,2,"run notepad","exec 'notepad';")
go
insert into notification_reaction (note_rule_id,reaction_id) values (1,1)

go
insert into analysis_rule (analysis_rule_id,type,name,description,active,rule_def) values (1,'Perl','IsTxnrouterRunning?','Finds any tasks or components that have "Exited With Error" status','Y','require siebsrvobj;

my $href;     	# refrence to a hash
my @error;   	# list of task errors   

my @alltasks; 	#  array of server task records


my $entobj = siebsrvobj->newobj($datasession,$debug,''siebel'');  	#initialize the enterprise object
@alltasks = $entobj->entasks();  				#get array of all server tasks


foreach  $href (0..$#alltasks) {  				#loop through the tasks
		
     my $errstring = "task: $alltasks[$href]{cc_alias} = $alltasks[$href]{tk_disp_runstate}\n";  	 #create a string definintion	
     print $errstring;  							 	 #for debugging...

     #look for the string "Exited with error".... if there is an error, add a string to the @error array, which will be emailed...eventually
      if ($alltasks[$href]{tk_disp_runstate} =~ /Exited with error/) {push @error, "FOUND THE FOLLOWING TXN ERROR: $errstring\n"}		  
  }

if (@error == 0) { #the number of errors == 0, so $retval = 1 
	$retval = 1;
	#errormessage overide = @errors
}')
go
insert into analysis_errdef(analysis_rule_id, error_defs_id) values (1,1)

 
insert collector(collector_id,type,execution_interval,name,description,active,rule_def) values (1,'Perl','60','Central Server up time','Time in seconds that the Central Server machine has been running','Y','$retval = Win32::GetTickCount() / 3600000;')
GO

insert collector(collector_id,type,execution_interval,name,description,active,rule_def) values (7,'Perl','60','WMI Uptime','Wrong Number hours that Central Server has been running -via WMI','Y','
my $WMIServices = Win32::OLE->GetObject( "winmgmts:{impersonationLevel=impersonate,(security)}//." ) || die;

my $computerobj = $WMIServices->ExecQuery ("Select  LastBootUpTime from Win32_OperatingSystem");

foreach  my $key (in ($computerobj)) {
	
	print "$key->{LastBootUpTime}\n";
	ConvWMITime($key->{LastBootUpTime});

}


sub ConvWMITime {
	my $wmiTime = shift;

	my $yr = substr($wmiTime,0,4);
	my $mo = substr($wmiTime,4,2);
	my $dy = substr($wmiTime,6,2);
	my $hr = substr($wmiTime,8,2);
	my $mn = substr($wmiTime,10,2);
	my $sec = substr($wmiTime,12,2);

	print "year = $yr, $mo, $dy $hr:$mn:$sec";

my   ($gsec,$gmin,$ghour,$gmday,$gmon,$gyear) = gmtime;

	print "year = $gyear\n"; 
	$gyear= $gyear + 1900;
	$gmon = $gmon + 1;

 	my ($dd,$dh,$dm,$ds) = Date::Calc::Delta_DHMS(  $yr,$mo,$dy,$hr,$mn,$sec,  $gyear,$gmon,$gmday,$ghour,$gmin,$gsec);

	print "date difference:\ndays diff = $dd\nhoursiff = $dh\nminsdiff = $dm\nsecs diff = $ds\n"; 
$retval = $dh;
}')
GO

insert into data_source(data_source_id,name,alias,username,password,host) values ('1','SiebSrvr_siebel','siebeldata','SADMIN','SADMIN','K6Z7E4')
GO