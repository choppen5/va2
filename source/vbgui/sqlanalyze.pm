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

	 unless($self->{SQLSTATEMENT} =~ /count\(\*\)/) {$self->{ERROR} = "Count(*) must be used in select statement for this object\n";}
	 $self->{SQLSTATEMENT} =~ s/count\(\*\)/count\(\*\) 'count'/;			 

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



sub returnsinglevalue {
	my $class = shift;

	 my $self ={
				SQLSTATEMENT => shift,
				DATASESSION => shift, #win32 odbc sessiong
				VALUEFIELD=> shift,
				VALUE=> undef,
	 };

	# $self->{SQLSTATEMENT} =~ s/MAX\(TXN_ID\)/MAX\(TXN_ID\) \"" /;	#alias the value field so it will return the same regardless of DB server		 

	print "RETURN SINGLE VALUE sql statement = " .$self->{SQLSTATEMENT} . "\n";


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



sub execsqltimer {
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

return 1;
