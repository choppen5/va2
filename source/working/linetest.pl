

$line = "Sat Nov 10 06:11:58 2007: SERVER LINE = ServerLog	ProcessCreate	1	000012a047350b4c:0	2007-11-10 06:11:35	Created multithreaded server process (OS pid = 	3476	) for SRBroker";
$line = "ServerLog	ProcessCreate	1	0	2007-11-03 21:12:55	Created server process (OS pid = 43776) for Server Tables Cleanup with task id 15379";

#Created multithreaded server process (OS pid = 	3476	) for SRBroker";

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
		} elsif ($line =~ /OS pid =\s+(\d+)\s+\)\s+for\s+([a-zA-Z_0-9-\s]+)/) {
			#this is the siebel 8 version - has no with task id message
			$pid = $1;
			$cc_alias = $2;	
		}					

		print "pid = $pid cc_name = $cc_name cc_alias = $cc_alias tid = $tid\n";
}


