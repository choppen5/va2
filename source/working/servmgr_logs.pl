#SIEBPPRD2.SIEBPPRD101.log
$debug=1;
open( PFH, 'C:\charles\vadmin2\siebelfiles\siebel.IBMT42.log' )or print(" couldnt open $file");
				
	while (<PFH>) {
		print "line =$_\n";
		processpids($_, 1);
	}
				
##############################################################################################################
#sub processpids ($line) - reads line from server log, parses pids and task ids
#############################################################################################################

sub processpids {
	
	
	my $line = shift;
	chomp $line;
	my $tidsearch = shift;#only search for created tids if starting up - otherwise file new event will will catch it
	if ($debug) {print("SERVER LINE = $line")};
			
		  if ($tidsearch) {#only insert creation pids on startup
		 	
				if  ($line !~ /Server Scheduler/ && $line =~ /ProcessCreate/) {
					#print $line;
								
					my $pid;
					my $cc_name;
					my $tid;
					my $cc_alias;

					#siebel 7 changed many component names to include a (ENU) - notice the or | expresion in ($2) 
					if ($line =~ /OS pid = (\d+)\)\s+for\s+([a-zA-Z_0-9-\s]+\(\w+\) |[a-zA-Z_0-9-\s]+)with task id (\d+)/) {
						$pid = $1;
						$cc_name = $2;
						$tid = $3;
					} elsif ($line =~ /OS pid =\s+(\d+)\s+\)\s+for\s+([a-zA-Z_0-9-]+)/) {
						#this is the siebel 8 version - has no with task id message, has component alias so no spaces allowed
						$pid = $1;
						$cc_alias = $2;	
					}	

					if ($debug) {print("pid = $pid cc_name = $cc_name cc_alias = $cc_alias tid = $tid")}
					
					#$task_id,$pid,$cc_alias,$cc_name
					print($datasession,$debug,$lh,$srvmgrvars{server_name},$tid,$pid,$cc_alias,$cc_name,$host,$appserver_id);

					#insert into db
				}
		   }

		
		if ($tidsearch) {#only insert creation pids on startup
			if ($line =~ /Server Scheduler/) {
						$line =~ /OS pid = (\d+)\)[a-zA-Z_0-9-\s]+with task id (\d+)/;

						
						if ($debug) {print("finding based on tid - TID = $2")};
						findbasedontid($2);

					}
		}
		
		
		
			if ($line =~ /Process completed Successfully/) {
				$line =~ /:\d+\s+[a-zA-Z_0-9-]+\s+(\d+)/;

				#print "PROCESS COMPLETE = $1 - Deleteing Key $1\n";
				if (1) {print("PROCESS COMPLETE = $1 - Deleteing Key $1")};
				#vadmin::data1::deletepidbytid($datasession,$debug,$lh,$1,$appserver_id);

			}
		
			if ($line =~ /Process exited with error/) {
				$line =~ /:\d+\s+[a-zA-Z_0-9-]+\s+(\d+)/;

				#print "PROCESS EXITED WITH ERROR = $1 - Deleteing Key $1\n";
				if (1) {print("PROCESS EXITED WITH ERROR = $1 - Deleteing Key TID $1")};
				#vadmin::data1::deletepidbytid($datasession,$debug,$lh,$1,$appserver_id);
			}	
		

			if ($line =~ /Process was terminated/) {
				$line =~ /:\d+\s+[a-zA-Z_0-9-]+\s+(\d+)/;

				#print "PROCESS EXITED WITH ERROR = $1 - Deleteing Key $1\n";
				if (1) {print("Process was terminate = $1 - Deleteing Key TID $1")};
				#vadmin::data1::deletepidbytid($datasession,$debug,$lh,$1,$appserver_id);
			}	

			#CO 11/10/2007 - Siebel 8 messages
			if ($line =~ /Process (\d+) was terminated/) {
				#print "PROCESS EXITED WITH ERROR = $1 - Deleteing Key $1\n";
				if (1) {print("Process was terminate = $1 - Deleteing PID $1")};
				
				#vadmin::data1::deletepidbypid($datasession,$debug,$lh,$1,$host);
			}	

			if ($line =~ /Process (\d+) exited with error/) {
				#print "PROCESS EXITED WITH ERROR = $1 - Deleteing Key $1\n";
				if (1) {print("Process exited with error = $1 - Deleteing PID $1")};
				#vadmin::data1::deletepidbypid($datasession,$debug,$lh,$1,$host);
			}
			
			if ($line =~ /Process (\d+) completed Successfully/) {
				$line =~ /:\d+\s+[a-zA-Z_0-9-]+\s+(\d+)/;

				#print "PROCESS EXITED WITH ERROR = $1 - Deleteing Key $1\n";
				print("Process was terminate = $1 - Deleteing Key TID $1");
				
				#vadmin::data1::deletepidbytid($datasession,$debug,$lh,$1,$appserver_id);
			}	
	}


##############################################################################################################
#sub processpids ($tid) - opens log directory and looks for file with particular tid - then parses component and pid from that file
#############################################################################################################


sub findbasedontid {

my $tid = shift;
my $count;
my %files = undef;
my ( $file, $filename, $comp);
opendir (DIR, "$srvmgrvars{serverpath}\\log\\") || print("in findbasedontid could not open $srvmgrvars{serverpath}\\log\\");
	foreach $filename ( readdir DIR ) {
		my $file = $filename;
			if ($file =~ /(.*?)_$tid/ ) {
				my $compname = $1;
				if ($debug) {print("found component = $compname  from $tid\n")}
				
				open( PFH, "$srvmgrvars{serverpath}\\log\\$file" )or print("tid: couldnt open $file");
				while (<PFH>) {
						if ($count < 1) {
							$_ =~ /\b($compname)\b \b([0-9]+)\b \b([0-9]+)\b/;
								if ($debug) {$lh->log_print("found in sub file $2,$3,$1")};
								print($datasession,$debug,$lh,$srvmgrvars{server_name},$2,$3,$1,undef,$host,$appserver_id);
							$count++;
						}
				}
				close PFH or print("died $!");
			}	
	}
closedir DIR || print("died $!");
}
