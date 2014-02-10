
use Win32::IProcess
qw(
PROCESS_QUERY_INFORMATION PROCESS_VM_READ INHERITED INHERITED DIGITAL NOPATH
);  

print "\n Using Win32::IProcess version ", $Win32::IProcess::VERSION, "\n";
print " By Amine Moulay Ramdane <aminer\@generation.net>\n";
print "\n Please hit <Enter> to start the demo...: ";
<STDIN>;
print "\n";

my($obj)=new Win32::IProcess || die "Can not create an IProcess object..\n";

$obj->EnumProcesses(\@EnumInfo);
my($nbr)=scalar(@EnumInfo);
print "\nThe total running Processes is: [$nbr]\n\n";
printf("%15.14s%19.18s%19.18s%15.14s%7.6s\n\n","[Name]","[UserTime]",
       "[KernTime]","[StartTime]","[Pid]");
$size=scalar(@EnumInfo);
for($i=0;$i<$size;$i++)
{ $obj->Open($EnumInfo[$i]->{ProcessId},PROCESS_QUERY_INFORMATION | 
              PROCESS_VM_READ,INHERITED,\$Hnd); 
  $obj->GetStatus($Hnd,\$TimeInfo,DIGITAL);
  printf("%15.14s%19.18s%19.18s%15.14s%7.6s\n",$EnumInfo[$i]->{ProcessName},
  $TimeInfo->{UserTime},$TimeInfo->{KernelTime},$TimeInfo->{CreationTime},
  $EnumInfo[$i]->{ProcessId});
  $obj->CloseHandle($Hnd);
}
printf("\n\n%17.15s%15.14s%12.11s%12.11s%17.16s%20.19s%16.15s\n\n","[Name]","[PageFaults/s]",
         "[PeakWS]","[WS]","[QuotaPagedPool]","[QuotaNonPagedPool]","[PagefileUsage]");
for($j=0;$j<$size;$j++)
{#print "$EnumInfo[$j]->{ProcessName}:\n";
 $obj->GetProcessMemInfo($EnumInfo[$j]->{ProcessId},\$Info);
 printf("%17.15s%15.14s%12.11s%12.11s%17.16s%20.19s%16.15s\n",$EnumInfo[$j]->{ProcessName},
          $Info->{PageFaultCount},
       $Info->{PeakWorkingSetSize},$Info->{WorkingSetSize},$Info->{QuotaPagedPoolUsage},
       $Info->{QuotaNonPagedPoolUsage},$Info->{PagefileUsage});
}
for($k=0;$k<$size;$k++)
{print "\n\n$EnumInfo[$k]->{ProcessName}:\n";
 $obj->GetProcessModules($EnumInfo[$k]->{ProcessId},\@Info,NOPATH);
 printf ("%20.19s%18.17s%14.13s%13.12s\n\n","[ModuleName]","[ImageSize Bytes]",
           "[BaseAddress]","[EntryPoint]");
 for ( $l=0;$l < scalar(@Info);$l++ )
      {
        printf ("%20.19s%18.17s%14.13s%13.12s\n",$Info[$l]->{ModuleName},
         $Info[$l]->{ModuleImageSize},$Info[$l]->{ModuleBaseAddress},$Info[$l]->{ModuleEntryPoint});
      }
}

undef $obj; 



