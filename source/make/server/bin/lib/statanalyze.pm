package statanalyze;
use sqlanalyze;


sub newobj { 
	
	my $class = shift;
	my $self = {
		DATASESSION => shift,
		DEBUG => shift,
		STATNAME => undef,
		STATVALUE => undef,
		LASTESTTIME => undef
	};     
	bless($self);
	return $self;		
}

sub getlatest {
	my $self = shift;

	my $statname = shift;

	print "statname = $statname";

	my $sql = qq{ select val "val",time_stmp "time_stmp" from stat_vals t1 where t1.stat_vals_id in (
		select max(stat_vals_id) from stat_vals t2, collector t3 where 
		t2.collector_id = t3.collector_id and  t3.name = '$statname')
	};
	
	my $timesql = qq{ select val "val",time_stmp "time_stmp" from stat_vals t1 where t1.stat_vals_id in (
		select max(stat_vals_id) from stat_vals t2, collector t3 where 
		t2.collector_id = t3.collector_id and  t3.name = '$statname')
	};
		
	my $val = sqlanalyze->returnsinglevalue($sql, $self->{DATASESSION},'val');
	my $timestamp = sqlanalyze->returnsinglevalue($sql, $self->{DATASESSION},'time_stmp');

	$self->{STATVALUE} = $val;
	$self->{LATESTTIME} = $timestamp;

	return $val;
}


sub getstatgrowth {
	my $self = shift;

	my $statname = shift;

	print "statname = $statname";

	
	my $sql = qq{ select val "val",time_stmp "time_stmp", stat_vals_id "stat_vals_id" from stat_vals t1 where t1.stat_vals_id in (
		select max(stat_vals_id) from stat_vals t2, collector t3 where 
		t2.collector_id = t3.collector_id and  t3.name = '$statname')
	};
		
	my $maxval = sqlanalyze->returnsinglevalue($sql, $self->{DATASESSION},'val');
	my $maxid = sqlanalyze->returnsinglevalue($sql, $self->{DATASESSION},'stat_vals_id');

	#now get the previously collect max id

	
	my $nextomaxsql = qq{ select val "val",time_stmp "time_stmp",stat_vals_id from stat_vals t1 where t1.stat_vals_id in (
		select max(stat_vals_id) from stat_vals t2, collector t3 where 
		t2.collector_id = t3.collector_id and  t3.name = '$statname' and
		stat_vals_id != '$maxid')
	};


	my $nexttomax =  sqlanalyze->returnsinglevalue($nextomaxsql, $self->{DATASESSION},'val');

	$val = $maxval - $nexttomax;

	$self->{STATVALUE} = $val;

	return $self;
}



sub getstatvalbytime {


	my $self = shift;
	my $statname = shift;
	my $timeoffset = shift || 1;

	my $sql = qq{ select val "val",time_stmp "time_stmp" from stat_vals t1,collector t3 where 
				t1.collector_id = t3.collector_id and t1.time_stmp > getdate()- $timeoffset  and
				t3.name = '$statname' 
	};
	
	
	my $sql = qq{ select val "val",time_stmp "time_stmp" from stat_vals t1,collector t3 where 
				t1.collector_id = t3.collector_id and t1.time_stmp > getdate()- $timeoffset  and
				t3.name = '$statname' 
	};
	

	
	my $val = sqlanalyze->returnsinglevalue($sql, $self->{DATASESSION},'val');
	my $timestamp = sqlanalyze->returnsinglevalue($sql, $self->{DATASESSION},'time_stmp');

	$self->{STATVALUE} = $val;
	$self->{LATESTTIME} = $timestamp;
	


}

sub statthreshold {
     
     my $self = shift;
     my $statname = shift;
             my $threshold = shift;

             
             my $currentvalue = $self->getlatest($statname);

             print "statistic current value is =  $currentvalue\n" ;

             if ($currentvalue > $threshold) {
	print "current value of $statname higher than $threshold\n";
	return 0;
             } else { 
	return 1;
            }
      
}



return 1;