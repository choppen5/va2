
use vadmin::vconfig;
use vadmin::data1;
use strict;
use Log::Logger;
use Win32::Service;
use Win32;
use Frontier::Client;
use Win32::OLE;
use vadmin::datasender;

my $db = 'MSSQL';

Win32::OLE->Option(Warn => 3 );
# variables for use w/ in the script
my $dwError;
my $notificationType;
my $nNumNotificationsProcessed;
my $bExitOuterLoop; 
my $key;
my $nWaitResult;
my $watcher;


use vars qw(%hup $datasession);

%main::hup;    #hash of user preferneces
$main::datasession;

my $host = Win32::NodeName;

use Cwd 'abs_path';	    # aka realpath()
my $rootpath = abs_path("..");


print "Log path = $rootpath/log/vapplogmon.log\n";

my $lh = new Log::Logger "$rootpath/log/vapplogmon.log" || new Log::Logger "vapplogmon.log";    # global log file


use Win32::OLE::Const 'DirWatcherATL 1.0 Type Library';



$lh->log_print("HOST = $host");


my $watcher = Win32::OLE->new('DirWatcherATL.CATLDirectoryWatcher');
$lh->fail("Problem Loading DirWatcherATL: $@") unless $watcher;


#########
#get command line siebsrvr
#########


$lh->log_print("Start up.......");          # first log comment


if ( checkerror( %hup = vadmin::vconfig::openlog() ) ) {  
    die;  # create user preference hash or die
} 

my $debug = $hup{DEBUG};



$datasession = vadmin::data1::odbcsess($debug,$lh, $hup{VODBC}, $hup{USERNAME}, $hup{PASSWORD} ); 
 

$lh->log_print("Data Session initialized.......");


my $url  = "http://$hup{CENTRALSERVER}:$hup{CCPORT}/RPC2";
my $client = Frontier::Client->new( url   => $url,
					debug => $debug,
				  );

################################
# Moudule specific global vars #
################################

my %apphash; #hash of hashes that contains the log file dir as key, and hash of $logfile{$bytecount} as values
my %apphasherrors; #hash of hashes that contains the lof file dir as key, and hash of string error defs as values


		my %localapphash;
		my %localapphasherrors;
### Main Sub

&setupwatcher;

sub setupwatcher {
		#get all applications that have error definitions defined for them
		my @applications = &vadmin::data1::getaoh(  $datasession, $debug, $lh, "select logdir \"logdir\" from sft_elmnt where host like '$host' and sft_elmnt_id in (select sft_elmnt_id from sft_err_deff)");


		my $apphashval;
		my $href;



			for $href (@applications) {
				my %sqlreturnedlocalapphash = %$href;
				
				print "local dir = $sqlreturnedlocalapphash{logdir}\n";
				my $appdir = $sqlreturnedlocalapphash{logdir}; #add a backslash to the directory...

				#$appdir =~ tr/\\/\//;

				if (-d $appdir) {
					$appdir =~ tr/[A-Z]/[a-z]/;
					$localapphash{$appdir} = { &createfilehash($appdir) };
					$localapphasherrors{$appdir} = { &createerrorhash($appdir) };
				} else {
					$lh->log_print("WARNING: THE FOLLOWING DIRECTORY: $appdir : FAILED TO BE MONITORED BECAUSE IT DOES NOT EXIST.  MAKE SURE ALL ERROR DEFINITIONS ARE ASSOICATED WITH A SOFTWARE ELEMENT WITH A VALID LOG PATH");
				}
			}

			

				my $msgdir = "$rootpath/msg/";
				$msgdir =~ s/\//\\/g;
				$msgdir =~ tr/[A-Z]/[a-z]/;
				#$msgdir = "d:\\vadmin2\\source\\make\\client\\bin\\";
				#\source\\make\\client\\log\\
				
				
				print "MSGDIR = $msgdir";

				my %restartwatcher;
				$restartwatcher{RESTART} =  "RESTART APPLOG WATCHER";

				$localapphash{$msgdir} = { &createfilehash($msgdir) };
				$localapphasherrors{$msgdir} = {%restartwatcher };

		############################################
		#debug info
		############################################


			for $apphashval (keys %localapphash) {
				my $file;
				$lh->log_print("APPLICATION LOG DIR BEING MONITORED = $apphashval");
				for $file (keys %{ $localapphash{$apphashval} } ) {
					
					if ($debug) {$lh->log_print("MONITORING $file WITH $localapphash{$apphashval}{$file} BYTES")}
				
				}
			}


		##################################################################################
		# print out each app being monitored and the search strings for each log directory


			for $apphashval (keys %localapphasherrors) {
				my $file;
				#$lh->log_print("App dir being monitored = $apphashval");


				for $file (keys %{ $localapphasherrors{$apphashval} } ) {
					
						print "file  = $file\n";
						$lh->log_print("Search string For Application Log Dir: $apphashval = $file=$localapphasherrors{$apphashval}{$file}");
				
				}
			}

		##########################################################
		# for each app, call sub to add variable
		##########################################################

			my $filterstring; #concatenated filter string

			my %hashofdirs;
			for $apphashval (keys %localapphash) {
				my $file;
				my $mydir;
					
					print "hashofdirs mydir = $apphashval \n"; 
					$filterstring =  &addtowatcher($apphashval);

					my $dirfilter = substr($apphashval,0,2) . "\\";
					


					my $alldirs;
					my $dirmatch;
					my $previousfilter;

					for $alldirs(keys %hashofdirs) {
						
						print "dirfilter = $dirfilter and alldirs = $alldirs\n";
						if (substr($dirfilter,0,1) =~ substr($alldirs,0,1)) { 
							print "MATCH! $dirfilter = $dirfilter and alldris = $alldirs\n";
							$dirmatch = 1;
							$previousfilter = $hashofdirs{$alldirs};
						} else {
							$dirmatch = 0;
						}

					}

					 if ($dirmatch) {$filterstring = $filterstring . ";" . $previousfilter};
					 
					 if ($debug) {$lh->log_print("filterstring = $filterstring")};
					 $hashofdirs{$dirfilter} = $filterstring;

			}


			my $alldirs;
			for $alldirs (keys %hashofdirs) {
				
					print "alldris = $alldirs\n";
					$lh->log_print("List of file directories monitored: $hashofdirs{$alldirs}");
					&contructwatcher($hashofdirs{$alldirs},$alldirs);
		
			}


		%apphash = %localapphash; #hash of hashes that contains the log file dir as key, and hash of $logfile{$bytecount} as values
		%apphasherrors = %localapphasherrors; #hash of hashes that contains the lof file dir as key, and hash of string error defs as values


	#setup complete, start the blocking thread
	&initilize_dirwatcher;

}# end setupwatcher

##################
# main blocking thread
#################

sub initilize_dirwatcher {

	$lh->log_print("Inititalizing Directory Watcher....");
	while ($nWaitResult = $watcher->WaitForNotification(-1)) {

		  if( $nWaitResult == 0 )
		   {
			$lh->log_print("Wait Cancelled, or timed out...\n");
			$bExitOuterLoop = 1;
		   }
		   else
			{

			 do{			
				 $notificationType = $watcher->{'NotificationType'};
				 print ("####################### Notification type =  $notificationType ############################\n");
				 print ("####################### file dir = $watcher->{'FileDirectory'}, file name = $watcher->{'FileName'} ############################\n");
					 
				if ($debug) {$lh->log_print("notification = $notificationType")}
				if ($debug) {$lh->log_print("file dir = $watcher->{'FileDirectory'}, file name = $watcher->{'FileName'}")}

				&parsefile($watcher->{'FileDirectory'},$watcher->{'FileName'});			
				
				#check hash of error defs for this app.... if match raise notification


			 }until( !$watcher->GetNextNotification() );
			}
	}

}
#############################################################################
#sub parsefile ($filepath) - parses modified file - increments $size
#############################################################################
sub parsefile {
	
    my $filepath = shift;
	my $filename = shift;
	my $test;
	my $size;
	my $fullpath;

	$filepath =~ tr/[A-Z]/[a-z]/; 
	#$filename =~ tr/[A-Z]/[a-z]/;
	
	#	if ($hup{DBTYPE} =~ /MYSQL/)
	#	{ 
	#	    my $fullpath = "$filepath\$filename";
	#	}
	 my $fullpath = "$filepath\\$filename";


	print "file path ====== $filepath\n";;

	my $otherfilesize = $localapphash{$filepath}{$filename};
	
	print "RECORDED FILE SIZE = $otherfilesize\n";

	open( FH, $fullpath ) or $lh->log_print("couldnt open $fullpath");
    

	$size = (-s $fullpath);
	if ($size < $localapphash{$filepath}{$filename} ) { #the file size is smaller than the seek position- oops, must be a cycled file
		$localapphash{$filepath}{$filename} = 0; #start over from the begining
	}


	$test = seek (FH,$localapphash{$filepath}{$filename},1);

    
    while  (<FH>) {
			my $line = $_;
			chomp($line);

			print "\n\n==========$line=========\n\n" ;
            if ($debug) {$lh->log_print("LOG FILE UPDATE: $line")}
           


			my $errorid;
					
						if ($debug) {
								
								my $keys;
								for $keys (keys %apphasherrors) {
									print "filepath = $filepath\n";
									print "apphash erors keys = $keys\n";
									for $errorid (keys %{ $apphasherrors{$keys} }) {
									print "hash error = $apphasherrors{$keys}{$errorid} \n";
								}
						}


					}


					for $errorid (keys %{ $apphasherrors{$filepath} } ) {
						
						if ($debug) {$lh->log_print("line search = $line")}
						
						#only do a search if there is a search string entered in the error definition
						if ($apphasherrors{$filepath}{$errorid}) {
			
							if ($debug) {$lh->log_print("error string search = $apphasherrors{$filepath}{$errorid}")}

							 if ($line =~ /$apphasherrors{$filepath}{$errorid}/) { #we found a error
									
									if ($apphasherrors{$filepath}{$errorid} =~ /RESTART/) {
										$lh->log_print("RESTART MESSAGE RECIEVED - RESTARTING TO INITILIZE NEW ERROR DEFINITIONS\n");
										$watcher->UnWatchAllDirectories();
										&setupwatcher;


									} else {
										&senderror($errorid,$line,$fullpath);
									}
							 }
						 }
					
					}

	}
	

		$size = (-s $fullpath);		  
        $localapphash{$filepath}{$filename} = $size;

    close FH || print("could not close file - probable been deleted - $!");
}


#################################################################################
# Modify this function on 4/7/2006 by Anuva technology for the enhancement of VA2.
# Split the content of the $line which contain the Error string,Error Host and Path.
# We just remove the Error File from the $line to separate the Error file path.
# add one more argument in @args that is $filepath which is send the data to the Frontier::Client->call for further manipulation
#################################################################################
sub senderror {
	my $errorid = shift;
	my $line = shift;
	my $filepath = shift;

		##################################################################################
		#Modified this function on 8/4/2006 by Anuva technologies for the enhancement of VA2.
		#Add the if condition for changing the format of the filepath variable for running in the MySql enviornment.
		#First it convert the filepath in a single \,then it will convert the value of filepath in to the double \\.
		##################################################################################
	if ($hup{DBTYPE} =~ /MYSQL/)
		{
			$filepath =~ s/\\\\/\\/g;
			$filepath =~ s/\\/\\\\/g;
		}
   
	print "\n\n\nSENDERROR: FILEPATH = $filepath\n\n\n";

	my %errorinsertdef = &vadmin::data1::gethashrecord($datasession,$debug,$lh,"select t1.ev_level \"ev_level\", t1.ev_type \"ev_type\", t1.ev_sub_type \"ev_sub_type\", t2.sft_elmnt_id \"sft_elmnt_id\" from sft_error_defs t1, sft_elmnt t3, sft_err_deff t2 where t1.error_defs_id = t2.error_defs_id  and t2.sft_elmnt_id = t3.sft_elmnt_id and t1.error_defs_id = $errorid");

#errorinsert args = ($sft_elmnt_id,$server,$event_string,$usr_event_level,$usr_event_type,$usr_event_sub_type,$time, $error_defs_id,$cc_alias,$host)				
	
		$line =~ s/'/''/g; #pad quotes for sql insert
		
		$line = $line . "\nERROR HOST = $host";    #\nERROR FILE = $filepath";
		my $datestring = &getdatestring();
		
		$lh->log_print("Detected Event in Log File - Sending to $url via XML-RPC: $line");
		my @args = ($errorinsertdef{sft_elmnt_id},undef,$line,$errorinsertdef{ev_level},$errorinsertdef{ev_type},$errorinsertdef{ev_sub_type},$datestring, $errorid,undef,$host,"",$filepath);
		eval{$client->call('errorinsert',@args)};
		if ($@) {$lh->log_print("ERROR: Could not report event! :\t $@")}

}


#######################################
# sub to updatate the watcher
#######################################
sub addtowatcher {

my $strTheDirectoryIWantToWatch;
my $strIncludeFilter;

$strTheDirectoryIWantToWatch = 	shift;  #This is the only directory that we want notifications for...
$strIncludeFilter = $strTheDirectoryIWantToWatch .  "*";  #<-- so that we'll get notifications past the directory we want to watch.

#	The default FilterFlags are: dwCheckFileNameOnly | dwWatchedDirectoryNotLocked | dwNoWatchStartStopNotification
#
#
#	typedef enum 
#		{ 
#		  dwDontUseFilters = 1, //no checks for filters
#		  dwCheckFullPath = 2, //filters check the full file name and path against filter pattern
#		  dwCheckPartialPath = 4, //filters check the partial path: this is the part of the path AFTER the watched directory.
#		  dwCheckFileNameOnly	= 8, //filters check only the file name part of the file path. ie: "FileName.txt" is checked if C:\Temp\SubFolder\FileName.txt is modified
#		  dwCheckFileIsComplete	= 256,//FILTERS_CHECK_FILE_IS_COMPLETE
#		  dwCheckFileIsCompleteEx = 512,//FILTERS_CHECK_FILE_IS_COMPLETE_EX
#		  dwCheckUsingVBScriptRegularExpressions = 1024, //FILTERS_USE_VBSCRIPT_REGULAREXPRESSIONS
#		  dwWatchedDirectoryNotLocked = 2048
#		}DirWatcherFilterFlags;
#		
#		


 $watcher->{FilterFlags} = (dwWatchedDirectoryNotLocked | dwCheckFullPath);
$strIncludeFilter = $strIncludeFilter . ";" . $strTheDirectoryIWantToWatch; #plus the additional filter so that we'll know of the renaming of the watched folder.

print "strTheDirectoryIWantToWatch: " . $strTheDirectoryIWantToWatch . "\n";
print "strIncludeFilter: " . $strIncludeFilter . "\n";



	return $strIncludeFilter;

}

sub contructwatcher {

	my $strExcludeFilter;
	my $dwChangesToWatchFor;
	
	my $filter = shift;
	my $dir = shift;

	print "dir = $dir\n";

	$strExcludeFilter = ""; 
	#$dir =~ s/\\/\\\\/g;
	
	$dwChangesToWatchFor = dwChangeFileName | dwChangeDirName; #must specify the dwChangeDirName flag so that we can catch that the watched directory was renamed.


	my $dwError;
	$dwError = $watcher->WatchDirectory("$dir", # szDirToWatch - change this to move up one dir...
                         	     8 | 2 | 1 | 3, # dwChangesToWatchFor
                         	    1, 				    
								$filter, 
								$strExcludeFilter   );

		if ($dwError != 0){ 
			$lh->log_print("The directory: $dir couldn't be watched! ErrorCode: " . $dwError ) ;
		
		#send a error event if the directory couldn't be watched...
		#my @args = ($errorinsertdef{sft_elmnt_id},undef,$line,$errorinsertdef{ev_level},$errorinsertdef{ev_type},$errorinsertdef{ev_sub_type},$datestring, $errorid,undef,$host);
		#eval{$client->call('errorinsert',@args)};
		#if ($@) {$lh->log_print("ERROR: Could not report event! :\t $@")}

		}

}

######################################################
#createerrorhash - takes a dir, and gets the sft_elmnt install dir, then makes a hash of all search strings defined for that app (install dir)
#####################################################3

sub createerrorhash{
	my $dir = shift;
		##################################################################################
		#Modified this function on 8/4/2006 by Anuva technologies for the enhancement of VA2.
		#Add the if condition for changing the format of the dir variable for running in the MySql enviornment.
		#For MySql it will enter the data into the database when there is double \\.
		##################################################################################
		if ($hup{DBTYPE} =~ /MYSQL/)
		{
			
			$dir =~ s/\\/\\\\/g; 
			
		}
	
	my $eref;
	my %errstrings; #hash of error strings
	my @errors = &vadmin::data1::getaoh(  $datasession, $debug, $lh, "select  t1.search_string \"search_string\", t1.error_defs_id \"error_defs_id\" from sft_error_defs t1 where t1.error_defs_id in (select t2.error_defs_id from sft_err_deff t2 , sft_elmnt t3 where  t2.sft_elmnt_id = t3.sft_elmnt_id and t3.logdir = '$dir')" );

	for $eref (@errors) {
		my %localerror = %$eref;
			if ($debug) {$lh->log_print("search string = $localerror{search_string}")}
			$errstrings{ $localerror{error_defs_id} } =  $localerror{search_string} ;
		}
	
	return %errstrings;
}


##############################################################################################################
#sub createfilehash  () - used to set the global variable %files with a hash of files and there size on startup. 
#############################################################################################################

sub createfilehash {
	
	my $dir = shift;
    my %files = undef;
	my ( $file, $filename, $size, $comp );

    opendir DIR1,
      "$dir"
      || $lh->log_print(
        "could not open $dir directory");
    foreach $filename ( readdir DIR1 ) {
                
		$size = (-s "$dir/$filename");
		$files{$filename} = $size;
        
    }
    closedir DIR1 || $lh->log_print(" died $!");
	return %files;
}

#old shitty sub - 

sub checkerror {
    my %ehash = @_;
    if ( $ehash{ERROR} ) {
        $lh->log_print( $ehash{ERROR} );
        return 1;
    }
}

#old shitty sub -
sub checkscerr {
    my $err = shift;
    if ( $err =~ m/Error:/ ) {
        $lh->log_print($err);
        return 1;
    }
}

sub getdatestring {
		my $datestring;
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
				localtime(time);

	if ($db = 'MSSQL') {
		#01/01/1998 23:59:15
		$year = $year + 1900;
		$mon = $mon + 1;
		$datestring = "$mon/$mday/$year $hour:$min:$sec"		
	}

	return $datestring;
}
