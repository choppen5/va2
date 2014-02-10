package sqlanalyze;
use Win32;


sub sqlcount { 
	 my $class = shift;
	 my $self ={
				SQLSTATEMENT => shift,
				DATASESSION => shift, #win32 odbc sessiong
				COUNT=> undef,
				ERROR=> undef,
	 };

	 unless($self->{SQLSTATEMENT} =~ /count\(\*\)/) {print "Count(*) must be used in select statement for this object";$self->{ERROR} = "Count(*) must be used in select statement for this object\n";}
	 $self->{SQLSTATEMENT} =~ s/count\(\*\)/count\(\*\) \"count\"/;			 

	print "SQL COUNT SQL statement = " .$self->{SQLSTATEMENT} . "\n";
	if ($self->{DATASESSION}->Sql($self->{SQLSTATEMENT})) {
		print "SQL ERROR: " . $self->{DATASESSION}->Error();
	}
	else  {
      while($self->{DATASESSION}->FetchRow()) {
      %Data = $self->{DATASESSION}->DataHash();
         $self->{COUNT} = $Data{"count"};
	  }
	}
	bless($self);
	return $self->{COUNT};		
}



sub sqltimer {
	 my $class = shift;
	 my $self ={
				SQLSTATEMENT => shift,
				DATASESSION => shift, #win32 odbc session
				MAXRECORDS => shift || 30  #show 30 rows by default...similar to a siebel cursor

	 };
	my ($tics,$ntics,$pef);
	$tics = Win32::GetTickCount() ;
	print $self->{SQLSTATEMENT};
	print "\nSTARTING number of Tics = $tics\n";
	if ($self->{DATASESSION}->Sql($self->{SQLSTATEMENT})) {
		my ($ErrNum, $ErrText, $ErrConn) =  $self->{DATASESSION}->Error();
		$self->{ERROR} = "$ErrNum\t$ErrText\t$ErrConn";
		print $self->{ERROR};
	}
	else  {
	
	 my $currentcount;
	 ROW:	while($self->{DATASESSION}->FetchRow()) {
				$currentcount++;
				last ROW if ($currentcount > $self->{MAXRECORDS});		
			}
	}
	$ntics = Win32::GetTickCount() ;
	print "ENDING number of Tics = $ntics\n";
	my $dif = ($ntics - $tics);
	print "DIfference in tics = $dif\n";
	$perf  = $dif / 1000;
	print "DIfference in seconds = $perf\n";
	$self->{TIME} = $perf;
	return $perf;
}

sub returnsinglevalue {
	my $class = shift;
	 my $self ={
				SQLSTATEMENT => shift,
				DATASESSION => shift, #win32 odbc sessiong
				VALUEFIELD=> shift,
				VALUE=> undef,
	 };
	if ($self->{DATASESSION}->Sql($self->{SQLSTATEMENT})) {
		print "SQL ERROR: " . $self->{DATASESSION}->Error();
	}
	else  {
      while($self->{DATASESSION}->FetchRow()) {
      %Data = $self->{DATASESSION}->DataHash();
         $self->{VALUE} = $Data{$self->{VALUEFIELD}};#if multiple fields are fetched, the last one will be set to value
	  }
	} 
	return $self->{VALUE};		
}

sub newsqltimer { 
	 my $class = shift;

	 my $self ={
				SQLSTATEMENT => shift,
				DATASESSION => shift, #win32 odbc session
				BENCHMARK => shift,
				TIME => undef
	 };
	bless($self);
	return $self;		
}





sub execsqlcounter {
	$self = shift;

	if ($self->{DATASESSION}->Sql($self->{SQLSTATEMENT})) {
		$self->{ERROR} = "Error: " . $self->{DATASESSION}->Error();
	}
	else  {
      while($self->{DATASESSION}->FetchRow()) {
      %Data = $self->{DATASESSION}->DataHash();
         $self->{COUNT} = $Data{"count"};
	  }
	}
  
	return $self->{COUNT};
}# exec sql



sub execsqltimerbenchmark {
	$self = shift;
	my ($tics,$ntics,$pef);

	$tics = Win32::GetTickCount() ;
	print $self->{SQLSTATEMENT};
	if ($self->{DATASESSION}->Sql($self->{SQLSTATEMENT})) {
		my ($ErrNum, $ErrText, $ErrConn) =  $self->{DATASESSION}->Error();
		$self->{ERROR} = "$ErrNum\t$ErrText\t$ErrConn";
	}
	else  {
      #while($self->{DATASESSION}->FetchRow()) {
	  #}
	
	}
   
	$ntics = Win32::GetTickCount() ;
	$perf  = ($ntics - $tics) / 1000;
	$self->{TIME} = $perf;
	#print "if $self->{COUNT} $self->{OPERATOR} $self->{VALUE}\n";
   
	if ($self->{BENCHMARK} > $self->{TIME}) {
		#we beat the benchmark
		return $self;
	} 
	else {
		#benchmark failed
		return 0;
	}
}

sub getaoh{#db session, @componentlist)
	my $self = shift;
	my @aoh;
	my %Data;
	my ($db,$debug,$SqlStatement) = @_;

	#if ($debug) {print("\nDEBUG:  getaoh sql = $SqlStatement")}
	
	if ($self->execsql($db,$debug,$SqlStatement)) {

		  while($db->FetchRow()) {
		  %Data = $db->DataHash();
		  push @aoh, {%Data};

		}
		
	}

	return @aoh;
}


sub execsql {
	my $self = shift;
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


return 1;
