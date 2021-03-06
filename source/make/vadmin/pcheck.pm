package vadmin::pcheck;
use Win32::IProcess
qw(
PROCESS_QUERY_INFORMATION PROCESS_VM_READ INHERITED INHERITED DIGITAL NOPATH
);  
use strict;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(procrunning);


sub procrunning {

my ($i,%EnumInfo,@EnumInfo,$rvar,$size,$Hnd,@pids);
my $checkpid = shift;

my($obj)=new Win32::IProcess || die "Can not create an IProcess object..\n";

$obj->EnumProcesses(\@EnumInfo);
my($nbr)=scalar(@EnumInfo);
#print "\The running Processes are: \n\n";
$size=scalar(@EnumInfo);
for($i=0;$i<$size;$i++)
{ $obj->Open($EnumInfo[$i]->{ProcessId},PROCESS_QUERY_INFORMATION | 
              PROCESS_VM_READ,INHERITED,\$Hnd); 
  #$obj->GetStatus($Hnd,\$TimeInfo,DIGITAL);
  push @pids, $EnumInfo[$i]->{ProcessId};
  $obj->CloseHandle($Hnd);
}

undef $obj; 

$rvar = 0;
foreach (@pids) {
	if ($_ == $checkpid) {
	#print "pid = $_\n";
	$rvar = 1}
	}
return $rvar;

}


