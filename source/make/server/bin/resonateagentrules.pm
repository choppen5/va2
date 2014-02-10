package resonateagentrules;
use sqlanalyze;

# take in enterprise name to start
#1. appserver -> ip map - take in a hash of ip addresses to appservernames combo

#methods

#2. return total number of rules 
#3. return total number of rules per ip/appserver
#4. return total number of rules per component


#5. appserver-> return total number of processes for component/ siebel server
#6. appserver-> return total number of processes for @componentlist / siebel server
#8. appserver-> return total number of processes for @componentlist , siebel enterprise

#9. compare enterprise processes with resonate total rules
#10. take mapped appservers, compare per appserver @component list rule matching to Siebel processes



sub newobj { 
	
	my $class = shift;
	my $self = {
		DATASESSION => shift,
		DEBUG => shift,
		GATEWAY => shift
	}; 
	# return the resonate id for the gateway - there should only be one resonate per gateway (and only one gateway per host
	my $sql = "select t1.sft_elmnt_id \"sft_elmnt_id\" from sft_elmnt t1, sft_elmnt t2 where t1.parent_elmnt_id = t2.sft_elmnt_id and  t2.type = 'gateway' and t2.name = '$self->{GATEWAY}' and t1.type = 'resonate'";
	$self->{RESONATEID} = sqlanalyze->returnsinglevalue($sql,$self->{DATASESSION},"sft_elmnt_id");
	#print "resonateid  = $self->{RESONATEID} \n";
	bless($self);
	return $self;		
}

sub totalrules {
	my $self = shift;
	my $resonateid = $self->{RESONATEID};
	#print "resonateid  = $resonateid \n";

	my $sql = "select sum(rule_number) \"totalrules\" from resonate_ar where sft_elmnt_id = '$resonateid'";  
	my $rulecount = sqlanalyze->returnsinglevalue($sql,$self->{DATASESSION},"totalrules");

	return $rulecount;

}

sub rulesforcomponent {
	#returns number of rules per component accross all resonate servers
	my $self = shift;
	my $component = shift;
	my $resonateid = $self->{RESONATEID};

	my $sql = "select sum(rule_number) \"totalrules\" from resonate_ar where sft_elmnt_id = '$resonateid' and service = '$component'";  
	my $rulecount = sqlanalyze->returnsinglevalue($sql,$self->{DATASESSION},"totalrules");

}

sub rulesforserver {
	#returns takes in server for resonate (resonate servers are IP addresses instead of Siebel server names)
	my $self = shift;
	my $service_host = shift;
	my $resonateid = $self->{RESONATEID};

	my $sql = "select sum(rule_number) \"totalrules\" from resonate_ar where sft_elmnt_id = '$resonateid' and service_host like '$service_host'";  
	my $rulecount = sqlanalyze->returnsinglevalue($sql,$self->{DATASESSION},"totalrules");

}

sub rulesforservercomponent {
	#takes in ip address of  resonate server and component name, returns number for that server/service combo
	my $self = shift;
	my $service_host = shift;
	my $component = shift;
	my $resonateid = $self->{RESONATEID};

	my $sql = "select sum(rule_number) \"totalrules\" from resonate_ar where sft_elmnt_id = '$resonateid' and service_host like '$service_host' and service = '$component'";  
	my $rulecount = sqlanalyze->returnsinglevalue($sql,$self->{DATASESSION},"totalrules");

}

sub rulecomparison {
	#returns as error string if any siebel active components do not match resontat rule numbers
	my $self = shift;
	my $siebsrvobj = shift;
	my %map = @_;
	my %sieb = $siebsrvobj->hashoflowercaseactivecomps(); #returns a hash of lowercase components and active processes 
	my $reserrorstring;

	my @complist  = @{ $map{COMPONENTLIST} }; #derefrenced list of components

	for my $ip (keys %map) {
		print "ip = $ip\n";
		next if $ip =~ /COMPONENTLIST/; 
		my $siebelserver = $map{$ip};	
		foreach my $comp (@complist) {
			print "comp = $comp\n";
			#get resonate total for comp
			my $restotal = $self->rulesforservercomponent($ip,$comp);
			#get siebel server total for comp
			my $siebeltotal = $sieb{$siebelserver}{$comp}{'cp_actv_mt'};
			if ($restotal != $siebeltotal) {
				$reserrorstring = $reserrorstring . "ERROR: $siebelserver $comp has $restotal resonate rules. SiebelServer processes for $comp = $siebtotal\n";
			}
			print "for $siebelserver total =  $siebeltotal for $ip total = $restotal \n";  			
		}
	}
	return $reserrorstring;
}


sub rulecomparison_nomap {
	#returns as error string if any siebel active components do not match resontate rule numbers
	my $self = shift;
	my $siebsrvobj = shift;
	my @complist = @_;
	my %map; #map between ip address and siebel server names will be dynamically built in this function

	#get resonate hosts
	my $sql = "select distinct service_host \"service_host\" from resonate_ar";
	my @resservers = sqlanalyze->getaoh($self->{DATASESSION},0,$sql);

	#for each resonate host(ip) get siebel server name
	for my $i (0..$#resservers) {
	  my $service_host = $resservers[$i]{service_host};
	  #use ip address to get siebel server name
	  my $sql = "select t2.name \"siebelserver\" from host t1, sft_elmnt t2 where t2.host = t1.hostname and t2.type = 'appserver' and t1.ipaddress like '$service_host'";
	  my $siebservername = sqlanalyze->returnsinglevalue($sql,$self->{DATASESSION},"siebelserver");
	  $map{$service_host} = $siebservername;
	}
	
	#change component names to lower case	
	my %sieb = $siebsrvobj->hashoflowercaseactivecomps(); #returns a hash of lowercase components and active processes 
	my $reserrorstring;

	for my $ip (keys %map) {
		print "ip = $ip\n";
		next if $ip =~ /ADVANCED/; 
		my $siebelserver = $map{$ip};	
		foreach my $comp (@complist) {
			print "comp = $comp\n";
			#get resonate total for comp
			my $restotal = $self->rulesforservercomponent($ip,$comp);
			#get siebel server total for comp
			my $siebeltotal = $sieb{$siebelserver}{$comp}{'cp_actv_mt'};
			if ($restotal != $siebeltotal) {
				$reserrorstring = $reserrorstring . "ERROR: $siebelserver $comp has $restotal resonate rules. SiebelServer processes for $comp = $siebtotal\n";
			}
			print "for $siebelserver total =  $siebeltotal for $ip total = $restotal \n";  			
		}
	}
	return $reserrorstring;
}
1;