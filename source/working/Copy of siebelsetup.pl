#!/usr/bin/perl

use vadmin::vconfig;
use strict;
use Log::Logger;
use Win32::ODBC;
use Win32;

my $host = Win32::NodeName;


my ( $datasession, $key, %srvmgrvars );
my %hup;    #hash of user preferneces

my $lh = new Log::Logger "siebelsetup.log";    # global log file
if ( checkerror( %hup = vadmin::vconfig::openlog() ) ) {  
    die;  # create user preference hash or die
} 

my $siebeluser = $ARGV[0];
my $siebelpassword = $ARGV[1];
my $gtwypath = $ARGV[2] || "siebns.dat";
my $siebversion = $ARGV[3];

unless ($siebeluser) {
	 print "Enter Siebel Username:\n"; 
	 $siebeluser = <STDIN>;
	 chomp($siebeluser);
}

unless ($siebelpassword) {
	print "Enter Siebel Password:\n"; 
	$siebelpassword = <STDIN>;
	chomp($siebelpassword);
}


print "\n\nPlease Verify:\nSiebel user = $siebeluser\nSiebel Password =  $siebelpassword\n";
print "Path to siebns.dat = $gtwypath\n";
print "OK TO BEGIN IMPORT?  Press N to cancel, or any other key to continue\n";
my $end = <STDIN>;
if ($end =~ /N/) {
	exit;
}


my $debug = $hup{DEBUG};
$datasession = odbcsess($debug,$lh, $hup{VODBC}, $hup{USERNAME}, $hup{PASSWORD} ); 
 

my @enterprises;
my @appservers;
my @entcomponents;

$lh->log_print("Full path to siebns.dat: $gtwypath");

open(NAMEFILE,
"$gtwypath") || $lh->fail("ERROR opening Gateways Server: $!");
my @contents=<NAMEFILE>;
close(NAMEFILE);

#insert some core stuff... this needs to be recompiled if we change the setup :( 

#Insert sft mng system
&execsql($datasession,$debug,$lh, "insert into sft_mng_sys(sft_mng_sys_id,name,type) values (1,'Virtual Administrator 2','VA2')");

#Insert 60 second default for system interval
&execsql($datasession,$debug,$lh, "insert into system_msg (system_msg_id,type,message) values (1,'1','60')");

#Insert default error defnitions
&execsql($datasession,$debug,$lh, "insert into sft_error_defs (error_defs_id,name,search_string,ev_level,ev_type,ev_sub_type) values (1,'Component Reached max tasks','','','Components Maxed','')");
&execsql($datasession,$debug,$lh, "insert into sft_error_defs (error_defs_id,name,search_string,ev_level,ev_type,ev_sub_type) values (2,'Transaction Backlog','','','Transaction Backlog','')");

&execsql($datasession,$debug,$lh, "insert into sft_error_defs (error_defs_id,name,search_string,ev_level,ev_type,ev_sub_type) values (3,'Process or Component exited with Error','Process exited with error','','Process exited with error','')");
 
#Insert default error defnitions
&execsql($datasession,$debug,$lh, "insert into notification_rule (note_rule_id,name, message,notify_all,active,type,ev_event_sub_type,ev_event_string) values (1,'Statistic Collector Timeout','Statistic Collector Timed Out-Set to Inactive','N','Y','TIMEOUT','COLLECTOR','')");
&execsql($datasession,$debug,$lh, "insert into notification_rule (note_rule_id,name, message,notify_all,active,type,ev_event_sub_type,ev_event_string) values (2,'Analysis Rule Timeout','Analysis Rule timed out-Set to Inactive','N','Y','TIMEOUT','ANALYSIS_RULE','')");

&execsql($datasession,$debug,$lh, "insert into notification_rule (note_rule_id,name, message,notify_all,active,type,ev_event_sub_type,ev_event_string) values (3,'Siebel Proc Exited with Error!','Siebel Process exited with Error','N','Y','Process exited with error','','')");

&execsql($datasession,$debug,$lh, "insert into notification_rule (note_rule_id,name, message,notify_all,active,type,ev_event_sub_type,ev_event_string) values (4,'Siebel Component Maxed','1 or More Siebel Component has reached Max Tasks','N','Y','Components Maxed','','')");
&execsql($datasession,$debug,$lh, "insert into notification_rule (note_rule_id,name, message,notify_all,active,type,ev_event_sub_type,ev_event_string) values (5,'Transaction Backlog','Warning!  Transaction Backlog detected','N','Y','Transacton Backlog','','')");




###################################
# get the enterprise name

################## sft_mgs_sys_insert

#my $prod_id; #store the product id for inserting sft_elemnts
my $version;
my $versionstring;

my $count;
foreach(@contents) {	#loop through every element in @contents, each is a line, stored in the $_ variable			
	$count++;
	#get version
	if ($count == 2) {

		 
		$versionstring = $_;
		chomp($versionstring);
		if (substr($_,0,1) =~ /6/) {
			$version = 6;
		} elsif (substr($_,0,1) =~ /7/){
			$version = 7;
		} 


		unless ($version) {
			my $entstring = '\/enterprises\/\w+\/version\/VersionString';
			$version = &returnvalue($entstring,1);

			print "version = $version\n";
			
			if ($version =~ /7/ || $version ) {
				#
			} elsif ($siebversion) {
				# mod 7/13/2007 
				$version = $siebversion
			} else (

				unless ($siebelpassword) {
					print "Enter Siebel Version:\n"; 
					$siebversion = <STDIN>;
					chomp($siebversion);
				}
				
				
				$lh->fail("Siebel Version $_ not supported. Exiting - contact support at www.recursivetechnology.com");

			}

		}
		
		print "Siebel VERSION: $version\n";

	}

#### new version information try



	
	if ($_ =~ /\[\/enterprises\/(\w+)]/) {		# this looks for [/enterprises/,then a word, \w+, followed by ]
												# if it matches, use ( ) to capture the \w+
			$lh->log_print("Slurped Siebel Enterprise: $1");		
			push @enterprises, $1;		#push into our array of enterprises
		}




	}	



########################################


#my $gwayid = &gatewayinsert($host,$gtwypath,$sys_id);
#$lh->log_print("Inserted Gateway for server $host");

my $sys_id = &sft_mgs_sys_insert($versionstring);  #insert a sft_mng_sys

#inserthost($host);







foreach  (@enterprises) {  #for each enterprise defined, set up functions to look for the particular value

	
#insert gateway and host

	my $bigstring;
	if ($version == 6) {
		$bigstring = "\/gateways\/default\/parameters\/GatewayHost";   	
	} else {
		$bigstring = "\/enterprises\/".$_."\/named subsystems\/ServerDataSrc\/parameters\/DSGatewayAddress";
	}

	$host =  &returnvalue($bigstring);	
	chomp($host);
	$host = cleanhost($host);
	
	my $gwayid = &gatewayinsert($host,$gtwypath,$sys_id);
	$lh->log_print("Inserted Gateway for server $host");

	inserthost($host);
	
########  Insert enterprise	
	my $entid =	&enterpriseinsert($gwayid,$_);
	$lh->log_print("Inserted Enterprise: $_");
	my $entname = $_; #reasign for later use
	chomp ($entname);




	########  Insert enterprise parameter values
	#to get the next enterprise value, just define the bigstring
	my $euname;
	my $bigstring = "\/enterprises/".$_."\/parameters\/Username";   		
	
	if ($version  == 6) {
	   $euname = &returnvalue($bigstring);
	} else {
		$euname = &returnvalue7($bigstring);
	}
	
	chomp($euname);

	#changed 1/15/2006 - take Siebel name from command line
	$lh->log_print("Inserted Enterprise Username = $euname");
	sft_elmnt_comp_insert("LOGIN",$siebeluser,$entid); 



	

	$bigstring = "\/enterprises/".$_."\/parameters\/Password";
	my $epword = &returnvalue($bigstring);
	chomp($epword);

	
	#changed 1/15/2006 - take Siebel name from command line
	sft_elmnt_comp_insert("PASSWORD",$siebelpassword,$entid); 
	$lh->log_print("Inserted Enterprise Password = $epword");

	
	#get dns name
	$bigstring = "\/enterprises/".$_."\/parameters\/Connect";
	my $dns;
	if ($version  == 6) {
	   $dns = &returnvalue($bigstring);
	} else {
		$dns = &returnvalue7($bigstring);
	}


	chomp($dns);

	#insert enterprise datasource
	
	#changed 1/15/2006 - take Siebel name from command line
	dns_insert($dns,$siebeluser,$siebelpassword);	


	


	##########
	#sft_elmnt_id,type,description,name,os,host,installdir,status,service_name,exe,sft_product_id,parent_elmnt_id

	my @appservers = &appsforent($_);

		
		

		foreach  (@appservers) {
		
			chomp($_);
			
			$bigstring = "/enterprises/$entname\/servers/$_\/parameters\/Host";
			my $apphost = &returnvalue($bigstring);
			chomp($apphost);
			$apphost = cleanhost($apphost);

			
			unless ($apphost =~ /$host/) {
				inserthost($apphost);
			}

			$bigstring = "/enterprises/$entname\/servers/$_\/parameters\/RootDir";
			my $installdir = &returnvalue($bigstring);
			chomp($installdir);
			$installdir =~ s/\\\\/\\/g;

			print "appserver installdir  = $installdir\n";

			my $service_name = "siebsrvr_".$entname."_".$_;
			my $appsrvrid = appserverinsert($_,$apphost,$installdir,$service_name,$entid);

			$lh->log_print("Inserted appserver $_");

			#insert Exited with error error definition for this app server
			sft_err_deff_insert($appsrvrid);

			
		
		}

	# CO commented 7/26/2006 - don't insert a bunch of components
	#my @entcomps =  &compsforent($_);
	my @entcomps = undef;

		foreach  (@entcomps) {
#			
				#&returndescriptvalue($_,$entname);

			$bigstring = "/enterprises\/$entname\/component groups\/\\w+\/components\/$_\/definition\/description";
			#print "bigstring = $bigstring\n";
			my $compdescrip =  &returnvalue($bigstring);
			chomp($compdescrip);
			#changed  1/21/2006 - inserst statement here seemed to insert one blank row, failing on Oracle
			#&compinsert($_,$compdescrip,$entid);

		}

}


sub compinsert {
	my ($cc_alias,$description,$sft_elmnt_id) = @_;
	my $id = keyincr($datasession,$debug,$lh,'components','components_id');
	
	execsql($datasession,$debug,$lh, "insert into components (components_id,cc_alias,description,log_analyze,sft_elmnt_id) values ($id,'$cc_alias','$description','N',$sft_elmnt_id)");

}



sub appserverinsert {
	my ($name,$apphost,$installdir,$service_name,$par_prod_id) = @_;
	my $id = keyincr($datasession,$debug,$lh,'sft_elmnt','sft_elmnt_id');
	

	$installdir =~ tr/[A-Z]/[a-z]/; 
	my $logdir = "$installdir\\log\\";


		##################################################################################
		#Modify this function on 8/4/2006 by Anuva technology for the enhancement of VA2.
		#Add the if..else loop for changing the formate of the Installdir and logdir field for running in the MySql enviornment.
		#For MySql it will enter the data into the databse when there is double \\.
		##################################################################################

	if ($hup{DBTYPE} =~ /MYSQL/)
		{
			$installdir =~ s/\\/\\\\/g; 
        	$logdir = "$installdir\\\\log\\\\";
		}
		else{

			$logdir = "$installdir\\log\\";
		}

	execsql($datasession,$debug,$lh,"insert into sft_elmnt (sft_elmnt_id,type,description,name,os,host,installdir,status,service_name,exe,parent_elmnt_id,logdir,monitor_service,restart_service,send_event) values ($id,'appserver','Siebel Application server','$name','NULL','$apphost','$installdir','NULL','$service_name','siebsvc.exe',$par_prod_id,'$logdir','Y','N','Y')");	
	
	my $nid = keyincr($datasession,$debug,$lh,'notification_rule','note_rule_id');
	execsql($datasession,$debug,$lh, "insert into notification_rule (note_rule_id,name,message,notify_all,type,ev_event_sub_type,active) values ($nid,'Service: $name Error', 'Service $service_name is not running on $apphost','N','Service Not Running','$service_name','Y')");
	
	
	return $id;
}





sub appsforent {
	my $ent = shift;

		foreach  (@contents) {  #loop through the whole file, again
			$count++;

			if ($_ =~ /\[\/enterprises\/$ent\/servers\/([a-zA-Z_0-9-]+)]/) {
				$lh->log_print("Siebel Appserver: $1");
				push @appservers, $1;
			}
		}

		return @appservers;
}


sub compsforent {
	my $ent = shift;

		foreach  (@contents) {  #loop through the whole file, again
			$count++;
	
		if ($_ =~ /\[\/enterprises\/$ent\/component list\/(\w+)]/) {
				$lh->log_print("Siebel Enterprise Component: $1");
				push @entcomponents, $1;
			}
		}


		return @entcomponents;
}




sub sft_mgs_sys_insert {
	my $sft_sysname = "Siebel " . $versionstring;
	my $id = keyincr($datasession,$debug,$lh,'sft_mng_sys','sft_mng_sys_id');
	execsql($datasession,$debug,$lh,"insert into sft_mng_sys (sft_mng_sys_id,name) values ($id,'$sft_sysname')");

	return $id;
}


sub sft_err_deff_insert {

	my $appserverid = shift;
	execsql($datasession,$debug,$lh,"insert into sft_err_deff (sft_elmnt_id,error_defs_id) values ($appserverid,3)"); #hard coded id of the Exited with Error error definition

}


sub sft_product_insert {
	my $name = "Siebel";
	my $par_sys_id = shift;
	my $vendor= shift;
	my $version = shift;

	my $id =  keyincr($datasession,$debug,$lh,'sft_product','sft_product_id');
	execsql($datasession,$debug,$lh,"insert into sft_product (sft_product_id,name,vendor,version,sft_mng_sys_id) values ($id,'$name','$vendor','$version',$par_sys_id)");

	return $id;
}


sub gatewayinsert {
	my ($host,$installdir,$par_prod_id) = @_;
	my $id = keyincr($datasession,$debug,$lh,'sft_elmnt','sft_elmnt_id');
	
	execsql($datasession,$debug,$lh,"insert into sft_elmnt (sft_elmnt_id,type,description,name,os,host,installdir,status,service_name,exe,sft_mng_sys_id,monitor_service,restart_service,send_event) values ($id,'gateway','Siebel Gateway','$host','NULL','$host','$installdir','null','gtwyns','siebsvc.exe',$par_prod_id,'Y','Y','Y')");	
	
	my $nid = keyincr($datasession,$debug,$lh,'notification_rule','note_rule_id');
	execsql($datasession,$debug,$lh, "insert into notification_rule (note_rule_id,name,message,notify_all,type,ev_event_sub_type,active) values ($nid,'Service gtwns Error', 'Service gtwyns is not running on $host','N','Service Not Running','gtwyns','Y')");
	
	
	
	return $id;
}

sub enterpriseinsert {
	my ($gwayid,$name) = @_;
	my $id = keyincr($datasession,$debug,$lh,'sft_elmnt','sft_elmnt_id');

	execsql($datasession,$debug,$lh,"insert into sft_elmnt (sft_elmnt_id,type,description,name,parent_elmnt_id) values ($id,'enterprise','Siebel Enterprise Server - Logical Entity','$name',$gwayid)");
	return $id;
}

sub sft_elmnt_comp_insert {
	my ($elmnt_key,$elmnt_val,$sft_elmnt_id) = @_;
	my $id = keyincr($datasession,$debug,$lh,'sft_elmnt_comp','sft_elmnt_comp_id');

	execsql($datasession,$debug,$lh,"insert into sft_elmnt_comp (sft_elmnt_comp_id,elmnt_key,elmnt_value,sft_elmnt_id) values ($id,'$elmnt_key','$elmnt_val',$sft_elmnt_id)");

}


sub dns_insert {
	my ($dns,$username,$password) = @_;
	my $id = keyincr($datasession,$debug,$lh,'data_source','data_source_id');
	
	$lh->log_print("Inserting Data Source = $dns");
	execsql($datasession,$debug,$lh,"insert into data_source (data_source_id,name,username,password,alias) values ($id,'$dns','$username','$password','siebeldata')");

}

sub cleanhost {
	my $cleanhost = shift;

	#if host has port in it, remove
	if ($cleanhost =~ /^(.*?):/) {
		$cleanhost = $1;
	} 
	#change to uppercase
	$cleanhost =~ tr/a-z/A-Z/; 
	
	print "host =  $host\n";
	return $cleanhost;
}


sub inserthost	{
	my ($host) = @_;
	my $id = keyincr($datasession,$debug,$lh,'host','host_id');
	my $alreadyexists;
	my $SqlStatement = "select hostname \"hostname\" from  host where hostname = '$host'";

		if (my $db = &execsql($datasession,$debug,$lh,$SqlStatement)) {
	
		  while($db->FetchRow()) {
	
			$alreadyexists = 1;
			}
		}

	unless ($alreadyexists) {
		$lh->log_print("Inserting Host = $host");
		execsql($datasession,$debug,$lh,"insert into host (host_id,hostname) values ($id,'$host')");
	}

}



sub returnvalue {
	my $bigstring = shift; #shift function takes the first value passed to a sub
	my $count = 0;
	my $offset = shift || 2;
	#print "bigstring = $bigstring\n";
	my ($key,$value);
	foreach  (@contents) {  #loop through the whole file, again
		$count++;

			
			if ($_=~/$bigstring/) {		#if we find a match
			
				($key,$value) = split(/=/,$contents[$count+$offset]); #split function splists arrays - we've mapped the fact 
																#that the value line will always be +2 
				$value =~ s/\"//g;								#remove quotes... i think there is a easier way	
				return $value;
			}
	
		
	}
}


sub returnvalue7 {
	my $bigstring = shift; #shift function takes the first value passed to a sub
	my $count = 0;
	my ($key,$value);
	foreach  (@contents) {  #loop through the whole file, again
		$count++;
		if ($_=~$bigstring) {		#if we find a match
		
			($key,$value) = split(/=/,$contents[$count+1]); #split function splists arrays - we've mapped the fact 
															#that the value line will always be +2 
			$value =~ s/\"//g;								#remove quotes... i think there is a easier way	
			return $value;

		}

		
	}
}


sub returndescriptvalue {
	my $compname = shift;
	my $entname = shift;
	my $count = 0;
	
	my $bigstring = "enterprises\/$entname\/component groups\/\\w+\/components\/$compname\/definition\/description";

	my ($key,$value);
	foreach  (@contents) {  #loop through the whole file, again
		$count++;
		if ($_=~ $bigstring ) {		#if we find a match
		
		#/enterprises\/$entname\/component groups\/\w+\/components\/$compname\/definition\/description/
			($key,$value) = split(/=/,$contents[$count+2]); #split function splists arrays - we've mapped the fact 
															#that the value line will always be +2 
			$value =~ s/\"//g;
			print "comd desc = $value\n";
			return $value;
			
		}

		
	}
}






sub keyincr {
	
	my ($db,$debug,$lh,$table,$primary_key,%Data,$SqlStatement,$retval) = @_;
	my $rethash;
	$SqlStatement = "select max($primary_key) \"increment\" from $table";
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
			 
				 $rethash++;
			 
		  }
		}
	return $rethash;
	}


sub execsql {

	my ($db,$debug,$lh,$SqlStatement) = @_;
	#if ($debug) {$lh->log_print("sql = $SqlStatement\n")};
	if ($db->Sql($SqlStatement)) {
	  $lh->log_print("SQL  failed = $SqlStatement");
	  my ($ErrNum, $ErrText, $ErrConn) = $db->Error();
      $lh->log_print("ERRORS: $ErrNum $ErrText $ErrConn");
	  return 0;

	   # add some function to try to reinitialize db session
	}  
	else {return $db}; 
}




sub checkerror {
    my %ehash = @_;
    if ( $ehash{ERROR} ) {
        $lh->log_print( $ehash{ERROR} );
        return 1;
    }
}


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

