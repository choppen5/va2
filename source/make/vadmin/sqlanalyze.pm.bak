#!/usr/bin/perl

package vadmin::sqlanalyze;
use Win32;


sub newsqlcount { 
	 my $class = shift;

	 my $self ={
				SQLSTATEMENT => shift,
				OPERATOR => shift,
				VALUE => shift,
				DATASESSION => shift, #win32 odbc sessiong
				COUNT=> undef
	 };

	 unless($self->{SQLSTATEMENT} =~ /count\(\*\)/) {$self->{ERROR} = "Count(*) must be used in select statement for this object\n";}
	 unless($self->{OPERATOR}) {$self->{ERROR} = "ERROR: The only operaters allowed are <,>, or =\n";}
	 unless($self->{VALUE} =~ /\d/) { $self->{ERROR} = "ERROR: Value must be numeric\n";}	    
		
	 $self->{SQLSTATEMENT} =~ s/count\(\*\)/count\(\*\) 'count'/;			 

	bless($self);
	return $self;		
}

sub newsqltimer { 
	 my $class = shift;

	 my $self ={
				SQLSTATEMENT => shift,
				DATASESSION => shift, #win32 odbc sessiong
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
   
	#print "if $self->{COUNT} $self->{OPERATOR} $self->{VALUE}\n";
   
	if ($self->{COUNT} > $self->{VALUE}) {
	return $self;
	} else {return 0;}
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
