package vadmin::vconfig;
use Cwd;
use strict;
use FileHandle;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(removelog openlog);


sub removelog {
	my ($file,$sec,$min,$hour,$day);
	my $cuwd = &cwd; #get current working directory
	opendir DIR, "."; 
	for (readdir DIR) {
		my $file = ".\\$_";
		if ($file =~ /vadmin2.log/) {
		($sec,$min,$hour,$day) = localtime[0,1,2,3];
			rename($file,"$cuwd//vadmin2".$day.$hour.$min.$sec.".logbak");
		}
	}
}#end removelog

sub openlog {	

my %User_Preferences;
my $curdir = shift || ".";
eval {
#print "$curdir\\vadmin.config\n";
open(CONFIG,"< $curdir\\vconfig.txt") || die "Error: couldn't find vconfig.txt local directory." 
};

if ($@) {
$User_Preferences{ERROR} = $@;
return %User_Preferences; 
  }

#parse log file
while (<CONFIG>) {
    chomp;                  # no newline  
    s/#.*//;                # no comments
    s/^\s+//;               # no leading white
    s/\s+$//;               # no trailing white
    next unless length;     # anything left?
    my ($var, $value) = split(/\s*=\s*/, $_, 2);
	#print LOG "$var = $value\n";
    $User_Preferences{$var} = $value;
  }
  close CONFIG;

  #add config checks here
  return %User_Preferences;     #user pref hash
}

