package vadmin::resonateagentrules;

use strict;
#runtime vsar packages have to start with main
#they need to take $datasession, $debug,$lh (from vsar) in as argument


sub runmain {
		
		my ($datasession,$debug,$lh) = @_;
		$lh->log_print("starting runmain");
		#get log directory for every resonate app


		my $sql = "select sft_elmnt_id \"sft_elmnt_id\", logdir \"logdir\" from sft_elmnt where type = 'resonate'";

		my @resorrays = vadmin::data1::getaoh($datasession,$debug,$lh,$sql);
		my $i;

		for $i (0..$#resorrays) { # this is each resonate instance we need monitor

			my $res_id =$resorrays[$i]{sft_elmnt_id}; 
			my $file = $resorrays[$i]{logdir} . "agent-rules.txt"; #expects logdir will end with \
			##my $file = 'c:\bellsouth\resonate\agent-rules.txt';

			my %service;

			open (FILE, "< $file") || die "could not open dir $file $!"; 

			while (<FILE>) {
				my $currentline = $_;  

				if ($currentline =~ /^SERVICE/) { #begins with SERVICE
						
						my @linearray = split(/\|/,$currentline,); #split pipes
						my $comp_name;
						my $pid;


						#look for a pattern of /eaiobjmgr_enu) or /eaiobjmgr_enu/ to determine component name
						if ($linearray[6] =~ /\/([a-zA-Z_]+)(\/|\))/) {
							$comp_name = $1;  #$1 is a special variable that captures ouput of the regular expression
						}
						
						
						if ($linearray[7] =~ /SERVERS\(([0-9.]+)\:/) {
							my $sip = $1; #$sip is the server ip address
							my $server;

							if ($linearray[7] =~ /\#/) { #if the ip address has # in it advanced rule
									$server = "ADVANCED";
								} else { 
									$server = $sip;
								}
							#update the hash with counters for this server/comp combo
							$service{$server}{$comp_name} =  $service{$server}{$comp_name} + 1;
						} #end if $linerray
					
				} #end if currentline

			} #end while
			close FILE;

			my %totalforserver;
			my %totalforcomp;

			foreach my $keys (keys %service) {
				print "$keys\n";
				#create a total for server
				
				foreach my $comp (keys %{$service{$keys}}) {
					#create a total for each component
					$totalforcomp{$comp} = $totalforcomp{$comp} + $service{$keys}{$comp};
					$totalforserver{$keys} = $totalforserver{$keys} + $service{$keys}{$comp};
					print "comp name = $comp has $service{$keys}{$comp} rules\n";

					#update or insert updated function - take in sft_elmnt_id, check server id appdress + component combo
					# if not there add row, if there upadte with value
					my $sql = "select rule_number \"rule_number\", resonate_id \"resonate_id\" from resonate_ar where service_host = '$keys' and service = '$comp' and sft_elmnt_id = $res_id";
					my %insertcheck = &vadmin::data1::gethashrecord($datasession,$debug,$lh,$sql);

					print "rule number = $insertcheck{rule_number}, resonate_id = $insertcheck{rule_number}\n";
					#if this guy doesn't exist, insert rule information

					if (!$insertcheck{resonate_id}) {
						my $newresid = vadmin::data1::keyincr($datasession,$debug,$lh,"resonate_ar","resonate_id");
						my $updatesql = "insert into resonate_ar (resonate_id,sft_elmnt_id,service,service_host,rule_number) values ($newresid,$res_id,'$comp','$keys','$service{$keys}{$comp}')";
						vadmin::data1::execsql($datasession,$debug,$lh,$updatesql);
					} elsif ($insertcheck{rule_number} != $service{$keys}{$comp}) {
						#only update if the curent parsed rule number doesn't match db version
						my $updatesql = "update resonate_ar set rule_number = $service{$keys}{$comp} where resonate_id = $insertcheck{resonate_id}";
						vadmin::data1::execsql($datasession,$debug,$lh,$updatesql);
					}

				}

			}

			print "\nTOTALS: --------------------------------------\n\n";

			foreach my $comptotal (keys %totalforcomp ) {
				print "Component total $comptotal  = $totalforcomp{$comptotal}\n";
			}


			my $total;
			foreach my $servertotal (keys %totalforserver ) {
				print "Server total $servertotal  = $totalforserver{$servertotal}\n";
				$total =  $total + $totalforserver{$servertotal};
			}

			print "total = $total\n";
		 } #end for i
}

sub cleanup {
	
		my ($datasession,$debug,$lh) = @_;
		$lh->log_print("starting cleanup resonateagentrules");
		#get log directory for every resonate app


		my $sql = "select sft_elmnt_id \"sft_elmnt_id\", logdir \"logdir\" from sft_elmnt where type = 'resonate'";

		my @resorrays = vadmin::data1::getaoh($datasession,$debug,$lh,$sql);
		my $i;

		for $i (0..$#resorrays) { # this is each resonate instance we need 

			my $sql = "delete from resonate_ar where sft_elmnt_id = $resorrays[$i]{sft_elmnt_id}";
			vadmin::data1::execsql($datasession,$debug,$lh,$sql);

		}

}


1;