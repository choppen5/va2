package siebsrvobj;
use va2reaction;
use Time::Local;


#useage - with constructor:

# use siebsrvobj;
# my $siebelobject = siebsrvobj->newobj($datasession,$debug,$enterprise); #($datasession is database connection to VA2 repository)


#methods 
#listed below are heavily used and usefull methods, enabling you to easily write rules about your siebel server

#$siebelobject->isentcomprunning($compalias);										#pass in siebel component alias - note this different than component name or description, returns true if it is running for any appserver in the enterprise
#$siebelobject->isappsrvrcomprunning($appserver,$comp);								#pass in appserver, component alias, returns true if the component is running for the specified siebel appserver
#$siebelobject->numoftasksforappsrvrcomp($appserver,$comp);							#pass in appserver, component alias, returns number of mt_tasks for the siebel appserver component
#$siebelobject->isenttaskrunning($taskalias);										#checks siebel enterprise to determine if specified task is running
#$siebelobject->isappsrvrtaskrunning($appserver,$taskalias);						#checks if specified siebel task is running for specified siebel appserver 
#$siebelobject->field_name_x_forappsrvrcomp($appservername,$compalias,$field_name);	#$fieldname is the VA2 database column (which matches the Siebel srvrmgr column name). This generic function can be used to return any field for a component per Seibel server
#$siebelobject->memuse_forappsrvrcomp($appserver,$comp,$memorytype);				#takes cc_name (instead of alias), as input, as that is what is mostly in the processes table type of memory = 1 = physical, 2 virtual, 3 = virtual + physical, returns total memory for Siebel component in MB
#$siebelobject->memuse_forappsrvr_processname($appserver,$processname,$memorytype);	#returns amount of memory used for siebel process, such as siebproc.exe, or siebmtsh.exe, etc)
#$siebelobject->memuse_forappsrvr($appserver,$type);								#returns sum of all memory used by siebel appserver in tracked processes
#$siebelobject->cputime_forappsrvr_processname($appserver,$process,$type);			#returns time in seconds of CPU time for siebel process name. 1, = total cpu time, 2 = kernel time for sieble process, 3 = usertime
#$siebelobject->cputime_forappsrvr_cc_alias($appserver,$alias,$type);				#returns time in seconds of CPU time for Siebel component alias, all process under the compoent
#$siebelobject->stopalltasksforcomponent($comp)										#stops all tasks for Siebel component
#$siebelobject->averagetasktime($taskalias,$appservername);							#returns average time in seconds a siebel task takes...this one is pretty high tech

##########jurys out on these...not used to often, use those above first

#$siebelobject->setenterprise();													#pass in a new name of the Siebel enterprise,if not added on contructor
#$siebelobject->runningappservers();												#returns a list of running siebel appservers - uses VA2 tables
#$siebelobject->isappsrvrunning($appserver);										#returns appserver name if it found to be running for enterprise - uses VA2 tables
#$siebelobject->activeforappsrvrcomp($appserver,$comp);								#pass in appserver, component, returns number of active processes for Siebel component
#$siebelobject->activeprocsforservercomplist($appserver,@componentlist);			#pass in appserver, array of components, returns total number of active processes for all the components
#$siebelobject->activeprocsenterprisecomplist(@componentlist);						#returns total number of active processes for all appservers in siebel enterprise for the list of components
#$siebelobject->sumtasksforcompappsrvr(@componentlist);								#take in a list of components, return sum of all active components for all components in the list for appservr
#$siebelobject->listofentappservers();												#returns array of siebel appservers for an enterprise
#$siebelobject->hashoflowercaseactivecomps();										#takes in siebel enterprise, returns a hash for each siebel server > lowercase(component) > cp_actv_mt
#$siebelobject->entcomps();															#returns and array of hashes, all active components in the siebel enterprise
#$siebelobject->entasks();															#returns and array of hashes, all active tasks in the siebel enterprise
#$siebelobject->$getapptasksforcomponent($taksalias,$appserver);					#returns array of hashes (records) for specific component
#$siebelobject->$getrunningapptasksforcomponent($taskalias,$appserver);				#returns array of hashes (records) for specific component, for tasks that running

sub newobj { 
	
	my $class = shift;
	my $self = {
		DATASESSION => shift,
		DEBUG => shift,
		ENTERPRISE => shift
	};     
	bless($self);
	return $self;		
}

sub setenterprise {
	my $self = shift;
	$self{ENTERPRISE} = shift;
	return $self;
}


sub runningappservers {
	my $self = shift;
	my $enterprise = $self->{ENTERPRISE};
	my $sql = "select t1.name \"name\" from sft_elmnt t1,sft_elmnt t2 where t1.parent_elmnt_id = t2.sft_elmnt_id and t1.type = 'appserver'  and t2.name = '$enterprise' and t1.status = 'RUNNING'";
	my @apparrays = getaoh($self->{DATASESSION},$self->{DEBUG},$sql);
	my @runningappservers;

	for $i (0..$#apparrays) {
		push  @runningappservers,$apparrays[$i]{name}
	}
	return @runningappservers;
}



sub isappsrvrunning {
	my $self = shift;
	my $appserver = shift;
	my $enterprise = $self->{ENTERPRISE};
	my $sql = "select t1.name \"name\" from sft_elmnt t1,sft_elmnt t2 where t1.parent_elmnt_id = t2.sft_elmnt_id and t1.type = 'appserver'  and t2.name = '$enterprise' and t1.status = 'RUNNING' and t1.name = '$appserver'";
	my @apparrays = getaoh($self->{DATASESSION},$self->{DEBUG},$sql);
	my $runningappservers;

	for $i (0..$#apparrays) {
	  $runningappservers = $apparrays[$i]{name}
	}
	
	return $runningappservers;
}


sub isentcomprunning {
	my $self = shift;
	my $compalias = shift;
	my $enterprise = $self->{ENTERPRISE};
	#my $sql = "select cp_disp_run_state from monitored_comps where cc_alias ='$compalias' and (cp_disp_run_state = 'Online' or cp_disp_run_state = 'Running')";
	my $sql = "select t1.cp_disp_run_state \"cp_disp_run_state\" from monitored_comps t1,sft_elmnt t2,sft_elmnt t3 where t1.cc_alias ='$compalias' and (t1.cp_disp_run_state = 'Online' or t1.cp_disp_run_state = 'Running') and t1.sft_elmnt_id = t2.sft_elmnt_id and t2.parent_elmnt_id = t3.sft_elmnt_id and t3.name = '$enterprise'";

	my @comparrays = getaoh($self->{DATASESSION},$self->{DEBUG},$sql);
	my $retval;

	for $i (0..$#comparrays) {
	  $retval = $comparrays[$i]{cp_disp_run_state}
	}
	
	print "Got status for $compalias = $retval\n";

	if ($retval =~ /Online/ || $retval =~ /Running/) {
		$retval = 1;
	} else {		
		$retval = 0;
	}
	
	return $retval;
}

sub isappsrvrcomprunning {
	my $self = shift;
	my $appservername = shift;
	my $compalias = shift;
	my $enterprise = $self->{ENTERPRISE};
	my $sql = "select t1.cp_disp_run_state \"cp_disp_run_state\" from monitored_comps t1,sft_elmnt t2,sft_elmnt t3 where t1.sv_name = '$appservername' and t1.cc_alias = '$compalias' and t1.sft_elmnt_id = t2.sft_elmnt_id and t2.parent_elmnt_id = t3.sft_elmnt_id and t3.name = '$enterprise'";
	my @retarray = getaoh($self->{DATASESSION},$self->{DEBUG},$sql);
	my $retval;

	for $i (0..$#retarray) {
	  $retval = $retarray[$i]{cp_disp_run_state}
	}

	print "Got status for $compalias = $retval\n";

	if ($retval =~ /Online/ || $retval =~ /Running/) {
		$retval = 1;
	} else {		
		$retval = 0;
	}

	return $retval;
}


sub numoftasksforappsrvrcomp {
	#returns 
	my $self = shift;
	my $appservername = shift;
	my $compalias = shift;
	my $enterprise = $self->{ENTERPRISE};
	my $sql = "select t1.cp_num_run \"cp_num_run\" from monitored_comps t1,sft_elmnt t2,sft_elmnt t3 where t1.sv_name = '$appservername' and t1.cc_alias = '$compalias' and t1.sft_elmnt_id = t2.sft_elmnt_id and t2.parent_elmnt_id = t3.sft_elmnt_id and t3.name = '$enterprise'";
	print "sql = $sql\n";
	my @retarray = getaoh($self->{DATASESSION},$self->{DEBUG},$sql);
	my $retval;

	for $i (0..$#retarray) {
	  $retval = $retarray[$i]{cp_num_run}
	}
	
	return $retval;
}

sub activeforappsrvrcomp {
	#returns the active process field from componnent "cp_actv_mt" which can be different than cp_num_run
	my $self = shift;
	my $appservername = shift;
	my $compalias = shift;
	
	return $self->field_name_x_forappsrvrcomp($appservername,$compalias,"cp_actv_mt");

}


sub activeprocsforservercomplist {
	# returns active processes for list of components for appserver
	my $self = shift;
	my $appservername = shift;
	my @componentlist = @_; #list of components
	
	my $sumprocs;
	foreach my $comp (@componentlist) {
		$sumprocs = $sumprocs + $self->activeforappsrvrcomp($appservername,$comp);
	}
	return $sumprocs;
}


sub activeprocsenterprisecomplist {
	# returns total number of active processes for all appservers in siebel enterprise for the list of components
	my $self = shift;
	my @complist = @_;

	my @siebelserverlist = $self->listofentappservers();
	my $sumofprocs;

	foreach my $siebserver (@siebelserverlist) {
		print "checking compolist for siebserver = $siebserver\n";
		$sumofprocs = $sumofprocs + $self->activeprocsforservercomplist($siebserver,@complist);
	}
	return $sumofprocs

}


sub sumtasksforcompappsrvr {
	#take in a list of components, return sum of all active components for all components in the list for appservr
	my $self = shift;
	my $appservername = shift;
	my @comps = shift;
	my $enterprise = $self->{ENTERPRISE};

	my $sum;
	foreach my $comp (@comps) {
		my $comprunning = $self->activeprocsforservercomplist($appserver,$comp);
		$sum = $sum + $comprunning;
		print "found $sum tasks so far\n";
	}
	return $sum;
}


sub field_name_x_forappsrvrcomp {
	my $self = shift;
	my $appservername = shift;
	my $compalias = shift;
	my $field_name = shift;
	my $enterprise = $self->{ENTERPRISE};
	my $sql =<<SQLEND;
	
		select t1.$field_name "$field_name" 
		from monitored_comps t1,sft_elmnt t2,sft_elmnt t3 
		where 
		t1.sv_name = '$appservername' 
		and t1.cc_alias = '$compalias' 
		and t1.sft_elmnt_id = t2.sft_elmnt_id 
		and t2.parent_elmnt_id = t3.sft_elmnt_id 
		and t3.name = '$enterprise'
SQLEND
;

	
	print "sql = $sql\n";
	my @retarray = getaoh($self->{DATASESSION},$self->{DEBUG},$sql);
	my $retval;

	for $i (0..$#retarray) {
	  $retval = $retarray[$i]{$field_name}
	}
	
	return $retval;
}

sub listofentappservers {
	#returns array of siebel appservers for an enterprise
	my $self = shift;
	my $enterprise = $self->{ENTERPRISE};

	my $sql = <<SQLEND;
	select t1.name "name" from sft_elmnt t1, sft_elmnt t2 where 
	t1.type = 'appserver' and
	t1.parent_elmnt_id = t2.sft_elmnt_id and
	t2.type = 'enterprise' and t2.name = '$enterprise'
SQLEND
;
		my @retarray = getaoh($self->{DATASESSION},$self->{DEBUG},$sql);
		my @appservers;

		for $i (0..$#retarray) {
			push @appservers, $retarray[$i]{"name"}
		}
	
	return @appservers;

}


sub hashoflowercaseactivecomps {
	#takes in siebel enterprise, returns a hash for each siebel server > lowercase(component) > cp_actv_mt
	my $self = shift;
	my %hash; #return hash
	my @appservers = $self->listofentappservers();
	foreach $app (@appservers) {
		#$hash{$app} = 
		# return list of monitored comps
		my $sql =<<SQLEND; 
	
		SELECT t4.cp_actv_mt "cp_actv_mt", cc_alias "cc_alias"   
		from sft_elmnt t2,sft_elmnt t3,monitored_comps t4 
		where  
		t2.sft_elmnt_id = t4.sft_elmnt_id 
		and t2.parent_elmnt_id = t3.sft_elmnt_id
		and t3.name = '$self->{ENTERPRISE}'
SQLEND
;
		my @monitoredcomps = getaoh($self->{DATASESSION},$self->{DEBUG},$sql);

		for my $i (0..$#monitoredcomps) {
			#change component name to lowercase
			 $monitoredcomps[$i]{"cc_alias"} =~ tr/A-Z/a-z/;
			 my $comp = $monitoredcomps[$i]{"cc_alias"};
			 my $active = $monitoredcomps[$i]{"cp_actv_mt"};
			 #finally, slam the hash together
			 $hash{$app}{$comp}{'cp_actv_mt'} = $active;
		} 
	} # finish looping appservers
	return %hash; #now has a hash of server > lowercasecomponent > numberofactiveprocesses
}


sub memuse_forappsrvrcomp {
	#takes cc_name as input, as that is what is mostly in the processes table 
	#type of memory = 1 = physical, 2 virtual, 3 = virtual + physical,
	my $self = shift;
	my $appservername = shift;
	my $cc_alias = shift;
	my $type = shift || 1; #default memory type = physical
	my $enterprise = $self->{ENTERPRISE};

	my $sumstring ;
	
		if ($type == 1) {
			$sumstring = "memory ";
		}

		if ($type == 2) {
			$sumstring = "virtualmem ";
		}

		if ($type == 3) {
			$sumstring = "memory + virtualmem ";
		}
	

	my $sql =<<SQLEND; 
	
		SELECT $sumstring "memsum" 
		from processes t1,sft_elmnt t2,sft_elmnt t3,monitored_comps t4 
		where 
		t4.cc_alias = '$cc_alias' 
		and (t4.cc_alias = t1.cc_alias or t4.cc_name = t1.cc_name) 
		and t1.sft_elmnt_id = t2.sft_elmnt_id
		and t2.sft_elmnt_id = t4.sft_elmnt_id 
		and t2.parent_elmnt_id = t3.sft_elmnt_id
		and t3.name = '$enterprise'
SQLEND
;

	print "sql = $sql\n";
	my @retarray = getaoh($self->{DATASESSION},$self->{DEBUG},$sql);
	my $retval;

	for $i (0..$#retarray) {
	  $retval = $retval + $retarray[$i]{'memsum'};
	}
	
	return $retval;
}


sub memuse_forappsrvr_processname {
	#takes cc_name as input, as that is what is mostly in the processes table
	my $self = shift;
	my $appservername = shift;
	my $process_name = shift;
	my $type = shift || 1;

	my $enterprise = $self->{ENTERPRISE};

	my $sumstring;
	
		if ($type == 1) {
			$sumstring = "memory ";
		}

		if ($type == 2) {
			$sumstring = "virtualmem ";
		}

		if ($type == 3) {
			$sumstring = "memory + virtualmem ";
		}
		
	my $sql =<<SQLEND;
	
		SELECT $sumstring "memsum" 
		from processes t1,sft_elmnt t2,sft_elmnt t3 
		where 
		t1.process = '$process_name' 
		and t1.sft_elmnt_id = t2.sft_elmnt_id 
		and t2.parent_elmnt_id = t3.sft_elmnt_id 
		and t3.name = '$enterprise'
SQLEND
;


	print "sql = $sql\n";
	my @retarray = getaoh($self->{DATASESSION},$self->{DEBUG},$sql);
	my $retval;

	for $i (0..$#retarray) {
	  $retval = $retval + $retarray[$i]{'memsum'};
	}
	
	return $retval;
}


sub memuse_forappsrvr {
	#returns sum of all memory used by appserver in tracked processes
	my $self = shift;
	my $appservername = shift;
    my $type = shift ||  1; #default memory - physical

	my $enterprise = $self->{ENTERPRISE};
	

		if ($type == 1) {
			$sumstring = "memory ";
		}

		if ($type == 2) {
			$sumstring = "virtualmem ";

		}

		if ($type == 3) {
			$sumstring = "memory + virtualmem";
		}
	

	my $sql =<<SQLEND; 
		SELECT $sumstring "memsum" 
		from processes t1,sft_elmnt t2,sft_elmnt t3 
		where 
		t1.sv_name = '$appservername' 
		and t1.sft_elmnt_id = t2.sft_elmnt_id 
		and t2.parent_elmnt_id = t3.sft_elmnt_id 
		and t3.name = '$enterprise'
SQLEND
;

	print "sql = $sql\n";
	my @retarray = getaoh($self->{DATASESSION},$self->{DEBUG},$sql);
	my $retval;

	for $i (0..$#retarray) {
	  $retval = $retval + $retarray[$i]{'memsum'}
	}	
	return $retval;
}




sub cputime_forappsrvr_processname {
	#takes cc_name as input, as that is what is mostly in the processes table
	my $self = shift;
	my $appservername = shift;
	my $process_name = shift;
	my $type = shift || 1;

	my $enterprise = $self->{ENTERPRISE};

	my $sumstring;
	
		if ($type == 1) {
			$sumstring = "cpu_time ";
		}

		if ($type == 2) {
			$sumstring = "kernel_time ";
		}

		if ($type == 3) {
			$sumstring = "user_time ";
		}
		
	my $sql = "SELECT $sumstring \"cpusum\" from processes t1,sft_elmnt t2,sft_elmnt t3 where t1.process = '$process_name' and t1.sft_elmnt_id = t2.sft_elmnt_id and t2.parent_elmnt_id = t3.sft_elmnt_id and t3.name = '$enterprise'";

	print "sql = $sql\n";
	my @retarray = getaoh($self->{DATASESSION},$self->{DEBUG},$sql);
	my $retval;

	for $i (0..$#retarray) {
	  $retval = $retval + $retarray[$i]{'cpusum'};
	}
	
	return $retval;
}

#################################################################################
#

sub cputime_forappsrvr_cc_alias {
	#takes cc_name as input, as that is what is mostly in the processes table
	my $self = shift;
	my $appservername = shift;
	my $cc_alias = shift;
	my $type = shift || 1;

	my $enterprise = $self->{ENTERPRISE};

	my $sumstring;
	
		if ($type == 1) {
			$sumstring = "cpu_time ";
		}

		if ($type == 2) {
			$sumstring = "kernel_time ";
		}

		if ($type == 3) {
			$sumstring = "user_time ";
		}
		
	
	my $sql = <<SQLEND;	
	
		SELECT cpu_time  "cpusum", t1.pid from processes t1,sft_elmnt t2,sft_elmnt t3,monitored_comps t4 where 
		t4.cc_alias = '$cc_alias' and (t4.cc_alias = t1.cc_alias or t4.cc_name = t1.cc_name)
		and t1.sft_elmnt_id = t4.sft_elmnt_id 
		and t4.sft_elmnt_id = t2.sft_elmnt_id 
		and t2.parent_elmnt_id = t3.sft_elmnt_id 
		and t3.name = '$enterprise'
SQLEND
;
	print "sql = $sql\n";
	my @retarray = getaoh($self->{DATASESSION},$self->{DEBUG},$sql);
	my $retval;
	for $i (0..$#retarray) {
	  $retval = $retval + $retarray[$i]{'cpusum'};
	}
	return $retval;
}


sub isenttaskrunning {
	my $self = shift;
	my $taskalias = shift;
	my $enterprise = $self->{ENTERPRISE};
	my $sql = "select t1.tk_pid \"tk_pid\" from server_task t1,sft_elmnt t2,sft_elmnt t3 where t1.cc_alias = '$taskalias' and t1.sft_elmnt_id = t2.sft_elmnt_id and t2.parent_elmnt_id = t3.sft_elmnt_id and t3.name = '$enterprise' and t1.tk_disp_runstate like '%Running%' ";
	my @retarray = getaoh($self->{DATASESSION},$self->{DEBUG},$sql);
	my ($retval,$pidrunning);

	for $i (0..$#retarray) {
	  $retval = $retarray[$i]{tk_pid};
	  if ($retval) {$pidrunning++};
	}
	return $pidrunning;
}

sub isappsrvrtaskrunning {
	my $self = shift;
	my $appservername = shift;
	my $taskalias = shift;
	my $enterprise = $self->{ENTERPRISE};
	my $sql = "select t1.tk_pid \"tk_pid\" from server_task t1,sft_elmnt t2,sft_elmnt t3 where t1.cc_alias = '$taskalias' and t1.sv_name = '$appservername' and t1.sft_elmnt_id = t2.sft_elmnt_id and t2.parent_elmnt_id = t3.sft_elmnt_id and t3.name = '$enterprise'";
	my @retarray = getaoh($self->{DATASESSION},$self->{DEBUG},$sql);
	my ($retval,$pidrunning);

	for $i (0..$#retarray) {
	  $retval = $retarray[$i]{tk_pid};
	  if ($retval) {$pidrunning++};
	}
	return $pidrunning;
}

sub entcomps {
	my $self = shift;
	my $enterprise = $self->{ENTERPRISE};
	my $sql = "select t1.sv_name \"sv_name\", t1.cp_max_mts \"cp_max_mts\", t1.cc_name \"cc_name\", t1.ct_alias \"ct_alias\", t1.cg_name \"cg_anme\", t1.cp_disp_run_state \"cp_disp_run_state\", t1.cp_num_run \"cp_num_run\", t1.cp_max_tas \"cp_max_tas\", t1.cp_actv_mt \"cp_actv_mt\", t1.cc_alias \"cc_alias\", t1.cp_start_time \"cp_start_time\", t1.cp_end_time \"cp_end_time\", t1.cp_status \"cp_status\", t1.sft_elmnt_id \"sft_elmnt_id\" from monitored_comps t1,sft_elmnt t2,sft_elmnt t3 where t1.sft_elmnt_id = t2.sft_elmnt_id and t2.parent_elmnt_id = t3.sft_elmnt_id and t3.name = '$enterprise'";
	my @retarray = getaoh($self->{DATASESSION},$self->{DEBUG},$sql);
	return @retarray;
}


sub entasks {
	my $self = shift;
	my $enterprise = $self->{ENTERPRISE};
	my $sql = "select t1.server_task_id \"server_task_id\", t1.sv_name \"sv_name\", t1.cc_alias \"cc_alias\",t1.tk_taskid \"tk_taskid\" ,t1.tk_pid \"tk_pid\",t1.tk_disp_runstate \"tk_disp_runstate\",t1.cc_runmode \"cc_runmode\",t1.tk_start_time \"tk_start_time\",t1.tk_end_time \"tk_end_time\",t1.tk_status \"tk_status\",t1.sft_elmnt_id \"sft_elmnt_id\", t1.cg_alias \"cg_alias\" from server_task t1,sft_elmnt t2,sft_elmnt t3 where t1.sft_elmnt_id = t2.sft_elmnt_id and t2.parent_elmnt_id = t3.sft_elmnt_id and t3.name = '$enterprise'";
	my @retarray = getaoh($self->{DATASESSION},$self->{DEBUG},$sql);
	return @retarray;
}

sub getapptasksforcomponent {
	my $self = shift;
	my $taskalias = shift;
	my $appservername = shift;

	my $enterprise = $self->{ENTERPRISE};
	my $sql = "select t1.server_task_id \"server_task_id\", t1.sv_name \"sv_name\", t1.cc_alias \"cc_alias\",t1.tk_taskid \"tk_taskid\" ,t1.tk_pid \"tk_pid\",t1.tk_disp_runstate \"tk_disp_runstate\",t1.cc_runmode \"cc_runmode\",t1.tk_start_time \"tk_start_time\",t1.tk_end_time \"tk_end_time\",t1.tk_status \"tk_status\",t1.sft_elmnt_id \"sft_elmnt_id\", t1.cg_alias \"cg_alias\" from server_task t1,sft_elmnt t2,sft_elmnt t3 where t1.cc_alias = '$taskalias' and t1.sv_name = '$appservername' and t1.sft_elmnt_id = t2.sft_elmnt_id and t2.parent_elmnt_id = t3.sft_elmnt_id and t3.name = '$enterprise'";
	my @retarray = getaoh($self->{DATASESSION},$self->{DEBUG},$sql);
	return @retarray;
}

sub getrunningapptasksforcomponent {
	my $self = shift;
	my $taskalias = shift;
	my $appservername = shift;

	my $enterprise = $self->{ENTERPRISE};
	my $sql = "select t1.server_task_id \"server_task_id\", t1.sv_name \"sv_name\", t1.cc_alias \"cc_alias\",t1.tk_taskid \"tk_taskid\" ,t1.tk_pid \"tk_pid\",t1.tk_disp_runstate \"tk_disp_runstate\",t1.cc_runmode \"cc_runmode\",t1.tk_start_time \"tk_start_time\",t1.tk_end_time \"tk_end_time\",t1.tk_status \"tk_status\",t1.sft_elmnt_id \"sft_elmnt_id\", t1.cg_alias \"cg_alias\" from server_task t1,sft_elmnt t2,sft_elmnt t3 where t1.cc_alias = '$taskalias' and t1.sv_name = '$appservername' and t1.sft_elmnt_id = t2.sft_elmnt_id and t2.parent_elmnt_id = t3.sft_elmnt_id and t3.name = '$enterprise' and tk_disp_runstate like '%Running%'";
	my @retarray = getaoh($self->{DATASESSION},$self->{DEBUG},$sql);
	return @retarray;
}


sub stopalltasksforcomponent {

	my $self = shift;
	my $component = shift;
	my $siebserver = shift;
	my @tasks = $self->getrunningapptasksforcomponent($component,$siebserver);
	my $href;

	foreach  $href (0..$#tasks) {  				#loop through the tasks
		 my $killtid = $tasks[$href]{tk_taskid};
		 print "taskid we want to kill = '$killtid\n";
		 #create reaction to kill specific TID
		 my $reactionid = va2reaction::createreaction("Kill $killtid",$siebserver,$siebserver,"STOP TASK $killtid");
		 print "reaction id = $reactionid\n";		 
		 #send a comand that will be executed on $siebserver
		 va2reaction::sendsiebelcommand($reactionid,$siebserver);
	}
}


sub averagetasktime {

	my $self = shift;
	my $taskalias = shift;
	my $appservername = shift;

	my @alltasks = getapptasksforcomponent($self,$taskalias,$appservername);
	my @times;
	foreach  my $href (0..$#alltasks) {  

		my $start = $alltasks[$href]{tk_start_time};  
		my $end =  $alltasks[$href]{tk_end_time};

		if ($end != "" and $end != 'NULL' && $end) {
			#we have an end
			print "about to convert start = $start and end = $end";
			my $diff = &returndiff($start,$end);
			print "dif = $diff\n";
			push(@times,$diff);
		}
	}
	my $averagetime = mean(@times);
	print "averagetime = $averagetime\n";
	return $averagetime;
}

sub getsiebserverbyip {
	
	

}


#############################################################################################################
# internal functions

sub getaoh{#db session, @componentlist)
my @aoh;
my %Data;
my ($db,$debug,$SqlStatement) = @_;
	#if ($debug) {print("\nDEBUG:  getaoh sql = $SqlStatement")}	
	if (&execsql($db,$debug,$SqlStatement)) {
		  while($db->FetchRow()) {
		  %Data = $db->DataHash();
		  push @aoh, {%Data};
		}	
	}
	return @aoh;
}


sub execsql {

	my ($db,$debug,$SqlStatement) = @_;
	#if ($debug) {$lh->log_print("sql = $SqlStatement\n")};
	if ($db->Sql($SqlStatement)) {
	  print("SQL  failed = $SqlStatement\n");
	  my ($ErrNum, $ErrText, $ErrConn) = $db->Error();
      print("ERRORS: $ErrNum $ErrText $ErrConn\n");
	  return 0;

	   # add some function to try to reinitialize db session
	}  
	else {return $db}; 
}


sub returndiff {
	my $timestart = shift;
	my $timeend = shift;
	$timestart = convertsecs($timestart);
	$timeend = convertsecs($timeend);
	my $delta = $timeend - $timestart;
	return $delta;
}

sub convertsecs {
		my $timestring = shift;
		my ($year1,$month1,$day1, $hour1,$min1,$sec1); 

		if ($timestring =~ /(\d+)\/(\d+)\/(\d+) (\d+)\:(\d+)\:(\d+)/ ) {
			$month1 = $1;
			$day1 = $2;
			$year1 = $3;					
			$hour1 = $4;
			$min1 = $5;
			$sec1 = $6;
			#print "parsed month =  $month1 - day = $day1 year = $year1 hour = $hour1 min = $min1 sec = $sec1\n";
		}
		my $time = timegm($sec1,$min1,$hour1,$day1,$month1,$year1);		
		#print "converted seconds = $time\n";
		return $time;
}

sub mean
{
  return unless @_;
  return $_[0] unless @_ > 1;
  return sum(@_)/scalar(@_);
}

sub sum
{
  return unless @_;
  return $_[0] unless @_ > 1;
  my $sum;
  foreach(@_) { $sum+= $_; }
  return $sum;
}
return 1;