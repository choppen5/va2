package vadmin::vsconfig;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(returnpaths returninterval);


sub returninterval{
	eval {
open(CONFIG,"< vservice.config") || die "Error: couldn't find vadmin.config file local directory." 
};

if ($@) {
$User_Preferences{ERROR} = $@;
print "could open file";
  }

while (<CONFIG>) {
next unless m/interval/;
print "matched interval\n";
 ($interval,$value) = split(/=/,$_);
}

close CONFIG;
return $value;
}



sub returnpaths{

eval {
open(CONFIG,"< vservice.config") || die "Error: couldn't find vadmin.config file local directory." 
};

if ($@) {
$User_Preferences{ERROR} = $@;
print "could open file";
  }

#parse log file
while (<CONFIG>) {
    s/#.*//;
	s/interval.*//;				# no comments
    s/^\s+//;               # no leading white
    s/\s+$//;               # no trailing white
    next unless length;     # anything left?
   #print "$_";
	 @args = split(/,/, $_);
     push @exeargs, [@args];
  }
  close CONFIG;

return @exeargs;
}




