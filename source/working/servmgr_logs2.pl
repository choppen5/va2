#siebel.IBMT42.log
$debug=1;
$lang = 'FRA';
open( PFH, 'SIEBPPRD2.SIEBPPRD101.log' )or print(" couldnt open $file");
				
	while (<PFH>) {
		#print "line =$_\n";
		processpids($_, 1);
	}
				
##############################################################################################################
#sub processpids ($line) - reads line from server log, parses pids and task ids
#############################################################################################################

sub processpids {
	
	
	my $line = shift;
	chomp $line;
	my $tidsearch = shift;#only search for created tids if starting up - otherwise file new event will will catch it
	#if ($debug) {print("SERVER LINE = $line\n")};
			
		  if ($tidsearch) {#only insert creation pids on startup
		 	
				if  ($line !~ /Server Scheduler/ && $line =~ /ProcessCreate/) {
					#print $line;
								
					my $pid;
					my $cc_name;
					my $tid;
					my $cc_alias;



					
					#lang specific matching
					if ($lang == 'FRA' ) {
						if ($line =~ /PID SE =\s+(\d+)\s+\)\s+\w+\s+([a-zA-Z_0-9-]+)/) {
								print "matched a $lang pattern\n";
								#this is the siebel 8 version - has no with task id message, has component alias so no spaces allowed
								$pid = $1;
								$cc_alias = $2;	
						}	
					} 
							#siebel 7 changed many component names to include a (ENU) - notice the or | expresion in ($2) 				
							if ($line =~ /OS pid = (\d+)\)\s+for\s+([a-zA-Z_0-9-\s]+\(\w+\) |[a-zA-Z_0-9-\s]+)with task id (\d+)/) {
								$pid = $1;
								$cc_name = $2;
								$tid = $3;
							} elsif ($line =~ /OS \w+ =\s+(\d+)\s+\)\s+\w+\s+([a-zA-Z_0-9-]+)/) {
								print "matched siebel 8 pattern\n";
								#this is the siebel 8 version - has no with task id message, has component alias so no spaces allowed
								$pid = $1;
								$cc_alias = $2;	
							}	
					

					print("PID MATCH ON SERVER SCHEDULER/PROCCESCREATE = $pid cc_name = $cc_name cc_alias = $cc_alias tid = $tid\n");
					
					#$task_id,$pid,$cc_alias,$cc_name
					#print($datasession,$debug,$lh,$srvmgrvars{server_name},$tid,$pid,$cc_alias,$cc_name,$host,$appserver_id);

					#insert into db
				}
		   }

}

	


##############################################################################################################
#sub processpids ($tid) - opens log directory and looks for file with particular tid - then parses component and pid from that file
#############################################################################################################

