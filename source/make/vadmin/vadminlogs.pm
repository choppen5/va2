package vadmin::vadminlogs;
use Cwd;
use strict;
use filehandle;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(removelog openlog openconfig parsecfgfile printerrorfatal ptime);


sub removelog {
	my ($file,$sec,$min,$hour,$day);
	my $cuwd = &cwd; #get current working directory
	opendir DIR, "."; 
	for (readdir DIR) {
		my $file = ".\\$_";
		if ($file =~ /vadmin2.log/) {
		($sec,$min,$hour,$day) = localtime[0,1,2,3];
			rename($file,"$cuwd\\vadmin2".$day.$hour.$min.$sec.".logbak");
		}
	}
}#end removelog

sub openlog {	
open(LOG, ">vadmin2.log");
autoflush LOG 1;
}

sub openconfig {#open config file or die
eval {
open(CONFIG,"< vadmin.config") || die "Can't find vadmin.config file in &cwd." 
};
&printerrorfatal();
&ptime;#first comments in log file
print LOG "#Config values: \n";
}


sub parsecfgfile {
#parse log file
my %User_Preferences;
while (<CONFIG>) {
    chomp;                  # no newline  
    s/#.*//;                # no comments
    s/^\s+//;               # no leading white
    s/\s+$//;               # no trailing white
    next unless length;     # anything left?
    my ($var, $value) = split(/\s*=\s*/, $_, 2);
	print LOG "$var = $value\n";
    $User_Preferences{$var} = $value;
  }
  return %User_Preferences;     #user pref hash
}
#################################################################################
#SUB printerrorfatal - prints fatal errors before dieing
#################################################################################

sub printerrorfatal {
if ($@) {
&ptime;
print LOG $@;
die; 
  }
}

#################################################################################
#SUB ptime - prints error messages to log file
#################################################################################

sub ptime {
my $time;
$time = localtime(time);
print LOG "$time\n";
}