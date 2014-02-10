package vaodbc;


sub createfromdsn { #create new data session based on key name of DSN in vadmin ds
	my $class = shift;
	my $datasession = shift; 
	my $alias = shift;
	my %Data;
	my $newsession;

	if ($datasession->Sql("Select name \"name\", username \"username\", password \"password\" from data_source where alias = '$alias'")) {
		print "ERROR: Can  not execute query\n";
	} else  {
      while($datasession->FetchRow()) {
      %Data = $datasession->DataHash();
         
	  }	
	$newsession = vaodbc->newodbcsession($Data{name}, $Data{username}, $Data{password});
	}
	
	return $newsession;
	
}

sub newodbcsession { 
	 my $class = shift;
	 my $db;

	my $dsn = shift;
	my $uid = shift;
	my $pwd = shift;


	print "DSN=$dsn;UID=$uid;PWD=$pwd;\n" ;
		

	if (!($db=new Win32::ODBC("DSN=$dsn;UID=$uid;PWD=$pwd"))) {
    print("Error connecting to $dsn");
	print("Error: " . Win32::ODBC::Error());
	}
    else {
		return $db;	
	}
		
}


sub closesession {
	my $self = shift;
	$self->{DATASESSION}->Close();
}


1;