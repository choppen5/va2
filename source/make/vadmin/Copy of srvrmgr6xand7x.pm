package vadmin::srvrmgr;
use filehandle;
use vadmin::siebparse;

#
# siebel::srvrmgr->new($gateway,$enterprise,$username,$password,$siebelserver,$installpath,$userdefinedsessionid);
# siebel::srvrmgr->startsession();
# siebel::srvrmgr->sendcommand($command);
# siebel::srvrmgr->parse_results();
# siebel::srvrmgr->changestatus($statuscode,$errorcode);
# siebel::srvrmgr->closesession();
#
# Example:
# $newsiebelsess = siebel::srvrmgr->new("gateway", "enterprise", "USERNAME", "PASSWORD", "SIEBELSERVER", "E:\\sea601\\siebsrvr",1);
# 
# $newsiebelsess->sendcommand("list components");
# %hashofarrays = $refe->parse_results;
#  
# $newsiebelsess->closesession(); 
#

sub new { 
	 my $class = shift;
	 my $lh = shift;
	 my $self ={
				GATEWAY => shift,
				ENTERPRISE => shift,
				USERNAME => shift,
				PASSWORD => shift,
				SERVERNAME => shift,
				SERVERPATH => shift,
				SESSID =>     shift,
				REDIRECTFILE => shift,#set this to true to have server manager redirect a file
				BINEXE => "\\bin\\srvrmgr.exe",
				VALIDPATH => 0,
				STATUS => 0,
				STARTIME => time(),
				SENTCOMMANDS => 0,
				FILEHANDLE => undef,
				FILEHANDLEREF => undef,
				SPOOLCOMMANDS => 1,
				SPOOLFILE => undef,
				AUTOFLUSH => 1,
				ERROR => undef
				};
	
	#set command to a srvrmgr executible
	$self->{COMMAND} = $self->{SERVERPATH}.$self->{BINEXE}." /g " . $self->{GATEWAY} . " /e " . $self->{ENTERPRISE} . " /u ".$self->{USERNAME}." /p " . $self->{PASSWORD} . " /s " . $self->{SERVERNAME};
	$self->{VALIDPATH} = (-f $self->{SERVERPATH}.$self->{BINEXE});
	unless ($self->{VALIDPATH}) {$lh->log_print("ERROR: Server path for $self->{SERVERNAME} : $self->{SERVERPATH} is INVALID.")}; #returns 1 if srvrmgr.exe is found
	$self->{FILEHANDLE} = $self->{SESSID}.$self->{STARTIME};       #creates a filehanle name based on start time and id
	$self->{SPOOLFILE} = $self->{FILEHANDLE}. "spool.txt";#creates a spoolfile name
    if ($self->{REDIRECTFILE}) {$self->{REDIRECTFILE} = " > ".$self->{FILEHANDLE}.".txt";
    }
     bless($self);
	 return $self;
}


sub startsession {
	my (%retcode,$key);
	#local *FILEH;
	$self = shift;
	$fileh = $self->{FILEHANDLE};
	print "srvmgr command = $self->{COMMAND}\n";
		if ($self->{VALIDPATH}) {
			open (FILEH, "| $self->{COMMAND} $self->{REDIRECTFILE}")or die "cannot start session coprocess: $!";
			autoflush FILEH 1;
			$self->{FILEHANDLEREF} = \*FILEH;
			$self->{STATUS} = 1;
			}
	
	return $self;

}


sub sendcommand {
	$self = shift;
	$command = shift;
	if ($self->{STATUS} != 0) {	#only send commands if session is running
			unlink ".\\$self->{SPOOLFILE}";
			$self->{SENTCOMMANDS}++;
			my $fileh = $self->{FILEHANDLEREF};
			if ($self->{SPOOLCOMMANDS} == 1) {print $fileh "spool ".$self->{SPOOLFILE} ."\n"};  #check to see if we spool commands or just send them
			#print "sending command to $fileh\n";
			print $fileh "$command\n";
			if ($self->{SPOOLCOMMANDS} == 1) {print $fileh "spool off\n"};
			until (-s ".\\$self->{SPOOLFILE}" > 0) { # this will warn until file exists to compare size
				select(undef,undef,undef,.2);}
		}#end status check
		sleep(1);
	return $self;
}

sub parse_results {
	$self = shift;
	open (SF,".\\$self->{SPOOLFILE}") || die "dead"; 
	my %hoa = parse_command_result(*SF);
	close SF;
	unlink ".\\$self->{SPOOLFILE}";
	return %hoa;
}

sub changestatus {
	$self = shift;
	my $statuscode = shift;
	my $errorcode = shift;
	if ($statuscode > 0) {
		$self->{STATUS} = 0;
		$self->{ERROR} = $errorcode;
	}
	print "status = $self->{STATUS}\n"; 
	return $self;
}

sub closesession {
	$self = shift;
	my $fileh = $self->{FILEHANDLEREF};
	print $fileh "exit\n";
	unlink ".\\$self->{SPOOLFILE}";
	#close $fileh;
	return $self;
}

1;