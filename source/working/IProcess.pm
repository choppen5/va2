#######################################################
#    Package: IProcess.pm - 1.41
#    Author : Amine Moulay Ramdane
#    Company: Cyber-NT Communications
#      Phone: (514)485-6659
#      Email: aminer@generation.net
#    Website: http://www.generation.net/~aminer/Perl
#       Date: July 30,1998
#Last update: May 28,2001
#
# Copyright © 2001 Amine Moulay Ramdane.All rights reserved
#######################################################

package Win32::IProcess;

use Win32::API;
use Carp;
use Config;
#use Win32::IIPC;
$VERSION = "1.41";
require Exporter;
@ISA = qw(Exporter);
@EXPORT =
qw(
);

@EXPORT_OK=qw(
PROCESS_ALL_ACCESS
PROCESS_QUERY_INFORMATION
PROCESS_VM_OPERATION
PROCESS_VM_READ
PROCESS_VM_WRITE
PROCESS_DUP_HANDLE
PROCESS_CREATE_PROCESS
PROCESS_SET_QUOTA
PROCESS_SET_INFORMATION
PROCESS_CREATE_THREAD
PROCESS_TERMINATE
CREATE_DEFAULT_ERROR_MODE
CREATE_NEW_CONSOLE
CREATE_NEW_PROCESS_GROUP
CREATE_NO_WINDOW
CREATE_SEPARATE_WOW_VDM
CREATE_SUSPENDED
CREATE_UNICODE_ENVIRONMENT
DEBUG_ONLY_THIS_PROCESS
DEBUG_PROCESS
DETACHED_PROCESS
HIGH_PRIORITY_CLASS
IDLE_PRIORITY_CLASS
NORMAL_PRIORITY_CLASS
REALTIME_PRIORITY_CLASS
THREAD_PRIORITY_ABOVE_NORMAL
THREAD_PRIORITY_BELOW_NORMAL
THREAD_PRIORITY_ERROR_RETURN
THREAD_PRIORITY_HIGHEST
THREAD_PRIORITY_IDLE
THREAD_PRIORITY_LOWEST
THREAD_PRIORITY_NORMAL
THREAD_PRIORITY_TIME_CRITICAL
DUPLICATE_SAME_ACCESS
DUPLICATE_CLOSE_SOURCE
SYNCHRONIZE
INHERITED
NONINHERITED
INFINITE
BYTES
KBYTES
FULLPATH
NOPATH
FLOAT
DIGITAL
TRUE
FALSE
NULL
NONE
SW_HIDE
SW_SHOWNORMAL
SW_SHOWMINIMIZED
SW_MAXIMIZE
SW_SHOWMAXIMIZED
SW_SHOWNOACTIVATE
SW_SHOW
SW_MINIMIZE
SW_SHOWMINNOACTIVE
SW_SHOWNA
SW_RESTORE
SW_SHOWDEFAULT
FOREGROUND_BLUE
FOREGROUND_GREEN
FOREGROUND_RED
FOREGROUND_INTENSITY
BACKGROUND_BLUE
BACKGROUND_GREEN
BACKGROUND_RED
BACKGROUND_INTENSITY
WAIT_ABANDONED
WAIT_OBJECT_0
WAIT_TIMEOUT
);


$DLLPath=".\\iproc.dll";
$DLLPath1=".\\iprocnt.dll";

#$DLLPath=$Config{installsitearch}."\\auto\\Win32\\IProcess\\iproc.dll";
#$DLLPath1=$Config{installsitearch}."\\auto\\Win32\\IProcess\\iprocnt.dll";

sub MAXLONG                         ()   {0x7FFFFFFF}
sub DEBUG_PROCESS                   ()   {0x00000001}
sub DEBUG_ONLY_THIS_PROCESS         ()   {0x00000002}
sub CREATE_SUSPENDED                ()   {0x00000004}
sub DETACHED_PROCESS                ()   {0x00000008}
sub CREATE_NEW_CONSOLE              ()   {0x00000010}
sub NORMAL_PRIORITY_CLASS           ()   {0x00000020}
sub IDLE_PRIORITY_CLASS             ()   {0x00000040}
sub HIGH_PRIORITY_CLASS             ()   {0x00000080}
sub REALTIME_PRIORITY_CLASS         ()   {0x00000100}
sub CREATE_NEW_PROCESS_GROUP        ()   {0x00000200}
sub CREATE_UNICODE_ENVIRONMENT      ()   {0x00000400}
sub CREATE_SEPARATE_WOW_VDM         ()   {0x00000800}
sub CREATE_SHARED_WOW_VDM           ()   {0x00001000}
sub CREATE_FORCEDOS                 ()   {0x00002000}
sub CREATE_DEFAULT_ERROR_MODE       ()   {0x04000000}
sub CREATE_NO_WINDOW                ()   {0x08000000}
sub THREAD_BASE_PRIORITY_LOWRT      ()   {15}
sub THREAD_BASE_PRIORITY_MAX        ()   {2}
sub THREAD_BASE_PRIORITY_MIN        ()   {-2}
sub THREAD_BASE_PRIORITY_IDLE       ()   {-15}
sub THREAD_PRIORITY_LOWEST          ()   {THREAD_BASE_PRIORITY_MIN}
sub THREAD_PRIORITY_BELOW_NORMAL    ()   {THREAD_PRIORITY_LOWEST + 1}
sub THREAD_PRIORITY_NORMAL          ()   {0}
sub THREAD_PRIORITY_HIGHEST         ()   {THREAD_BASE_PRIORITY_MAX}
sub THREAD_PRIORITY_ABOVE_NORMAL    ()   {THREAD_PRIORITY_HIGHEST - 1}
sub THREAD_PRIORITY_ERROR_RETURN    ()   {MAXLONG}
sub THREAD_PRIORITY_TIME_CRITICAL   ()   {THREAD_BASE_PRIORITY_LOWRT}
sub THREAD_PRIORITY_IDLE            ()   {THREAD_BASE_PRIORITY_IDLE}
sub SYNCHRONIZE                     ()   {0x00100000}
sub INHERITED                       ()   {1}
sub NONINHERITED                    ()   {0}
sub OWNED                           ()   {1}
sub NOTOWNED                        ()   {0}
sub INFINITE                        ()   {-1}
sub DUPLICATE_CLOSE_SOURCE          ()   {0x00000001}
sub DUPLICATE_SAME_ACCESS           ()   {0x00000002}
sub STANDARD_RIGHTS_REQUIRED        ()   {0x000F0000}
sub PROCESS_ALL_ACCESS              ()   {STANDARD_RIGHTS_REQUIRED | SYNCHRONIZE | 0xFFF}
sub PROCESS_QUERY_INFORMATION       ()   {0x0400}
sub PROCESS_VM_OPERATION            ()   {0x0008}
sub PROCESS_VM_READ                 ()   {0x0010}
sub PROCESS_VM_WRITE                ()   {0x0020}
sub PROCESS_DUP_HANDLE              ()   {0x0040}
sub PROCESS_CREATE_PROCESS          ()   {0x0080}
sub PROCESS_SET_QUOTA               ()   {0x0100}
sub PROCESS_SET_INFORMATION         ()   {0x0200}
sub PROCESS_CREATE_THREAD           ()   {0x0002}
sub PROCESS_TERMINATE               ()   {0x0001}
sub NULL                            ()   {0}
sub BYTES                           ()   {0}
sub KBYTES                          ()   {1}
sub FULLPATH                        ()   {1}
sub NOPATH                          ()   {0}
sub FLOAT                           ()   {1}
sub DIGITAL                         ()   {0}
sub FALSE                           ()   {0}
sub TRUE                            ()   {1}
sub SW_HIDE                         ()   {0}
sub SW_SHOWNORMAL                   ()   {1}
sub SW_SHOWMINIMIZED                ()   {2}
sub SW_MAXIMIZE                     ()   {3}
sub SW_SHOWMAXIMIZED                ()   {3}
sub SW_SHOWNOACTIVATE               ()   {4}
sub SW_SHOW                         ()   {5}
sub SW_MINIMIZE                     ()   {6}
sub SW_SHOWMINNOACTIVE              ()   {7}
sub SW_SHOWNA                       ()   {8}
sub SW_RESTORE                      ()   {9}
sub SW_SHOWDEFAULT                  ()   {10}
sub FOREGROUND_BLUE                 ()   {1}
sub FOREGROUND_GREEN                ()   {2}
sub FOREGROUND_RED                  ()   {4}
sub FOREGROUND_INTENSITY            ()   {8}
sub BACKGROUND_BLUE                 ()   {16}
sub BACKGROUND_GREEN                ()   {32}
sub BACKGROUND_RED                  ()   {64}
sub BACKGROUND_INTENSITY            ()   {128}
sub NONE                            ()   {-1}
sub WAIT_ABANDONED                  ()   {0x00000008}
sub WAIT_OBJECT_0                   ()   {0x00000000}
sub WAIT_TIMEOUT                    ()   {0x00000102}
sub COLOR1                          ()   {FOREGROUND_BLUE | FOREGROUND_GREEN | FOREGROUND_INTENSITY;}


sub new
{my($class)=shift;my($self)={};%$self=@_;bless($self,$class);
Load($self->{DLLPath});return $self;}

sub DESTROY
{my($obj)=shift; undef $CreateProcess; undef $SetProcessWorkingSet; undef $GetProcessWorkingSet;
undef $GetAffinityMask;undef $SetAffinityMask;undef $SetThrAffinityMask;undef $SetIdealProcessor;
undef $SetThreadPriority;undef $GetThreadPriority;undef $GetExitCode;undef $GetExitCodeThread;
undef $GetSystemCache;undef $SetSystemCache;undef $ClearSystemCache;undef $EnumDeviceDrivers;
undef $GetCurrentProcessId;undef $GetCurrentThreadId;undef $GetCurrentProcess;undef $FreeMem;
undef $GetProcessTime;undef $GetThreadTime;undef $GetProcessHandle;undef $GetThreadHandle;
undef $SuspendThread;undef $ResumeThread;undef $SetPriorityClass;undef $GetPriorityClass;
undef $TerminateProcess;undef $TerminateThread;undef $GetCommandLine;undef $ExitProcess;
undef $GetForegroundHwnd;undef $SetForegroundHwnd;undef $FindWindow;undef $ShowWindow;
undef $GetCurrentThread;undef $DuplicateHandle;undef $CloseHandle;undef $OpenProcess;
undef $GetThreadPriorityBoost;undef $WaitForObject;undef $WaitForMultipleObjects;
undef $GetProcessMemInfo; undef $ExitThread; undef $Sleep; undef $SwitchToThread;
undef $SetPriorityBoost;undef $SetThreadPriorityBoost;undef $GetPriorityBoost;

if(Win32::IsWinNT)
{undef $EnumProcesses;undef $GetProcessModules;undef $ReallocMem;}

if(Win32::IsWin95)
{undef $HideProcess;undef $KeyCtrl;undef $EnumProcesses;undef $GetProcessModules;undef $ReallocMem;}}

sub Load
{my($DLLPath2);
 if(defined($_[0]))
  {$DLLPath2=$_[0];
   $DLLPath=$DLLPath2.'\iproc.dll';
   $DLLPath1=$DLLPath2.'\iprocnt.dll';}
$CreateProcess=new Win32::API($DLLPath, "Create_Process", [P,P,I,I,P,P,I,I,I,I,I,I,P,P,P],N);
$SetProcessWorkingSet=new Win32::API($DLLPath,"SetWorkingSet",[I,I,I,P],I);
$GetProcessWorkingSet= new Win32::API($DLLPath,"GetWorkingSet",[I,P,P,P],I);
$GetProcessTime=new Win32::API($DLLPath,"GetProcTime",[I,P,P,P,P,P,P,P,P,P,P,P,P,P],I);
$GetThreadTime=new Win32::API($DLLPath,"GetThrTime",[I,P,P,P,P,P,P,P,P,P,P,P,P,P],I);
$GetProcessHandle=new Win32::API($DLLPath,"GetProcessHandle",[P,P],I);
$GetThreadHandle=new Win32::API($DLLPath,"GetThreadHandle",[P,P],I);
$GetCurrentProcessId=new Win32::API($DLLPath,"GetCurrentProcId",[P],I);
$GetCurrentThreadId=new Win32::API($DLLPath,"GetCurrentThrId",[P],I);
$GetCurrentProcess=new Win32::API($DLLPath,"GetCurrent_Process",[P],I);
$GetCurrentThread=new Win32::API($DLLPath,"GetCurrent_Thread",[P],I);
$DuplicateHandle=new Win32::API($DLLPath,"Duplicate_Handle",[I,I,I,I,I,P,P],I);
$CloseHandle=new Win32::API($DLLPath,"CloseThisHandle",[I,P],I);
$OpenProcess=new Win32::API($DLLPath,"OpenProc",[I,I,I,P,P],I);
$SuspendThread=new Win32::API($DLLPath,"Suspend_Thread",[N,P,P],I);
$ResumeThread=new Win32::API($DLLPath,"Resume_Thread",[N,P,P],I);
$SetPriorityClass=new Win32::API($DLLPath,"SetPriority_Class",[N,I,P],I);
$GetPriorityClass=new Win32::API($DLLPath,"GetPriority_Class",[N,P,P],I);
$SetThreadPriority=new Win32::API($DLLPath,"SetThread_Priority",[N,I,P],I);
$GetThreadPriority=new Win32::API($DLLPath,"GetThread_Priority",[N,P,P],I);
$GetExitCode=new Win32::API($DLLPath,"GetExitCodeProc",[N,P,P],I);
$GetExitCodeThread=new Win32::API($DLLPath,"GetExitCodeThr",[N,P,P],I);
$GetAffinityMask=new Win32::API($DLLPath1,"GetProcAffinity_Mask",[N,P,P,P],I);
$SetAffinityMask=new Win32::API($DLLPath1,"SetProcAffinity_Mask",[N,I,P],I);
$SetThrAffinityMask=new Win32::API($DLLPath1,"SetThrAffinity_Mask",[N,I,P,P],I);
$SetIdealProcessor=new Win32::API($DLLPath1,"SetIdealProcessor",[N,I,P,P],I);
$TerminateProcess=new Win32::API($DLLPath,"Terminate_Process",[N,I,P],I);
$TerminateThread=new Win32::API($DLLPath,"Terminate_Thread",[N,I,P],I);
$GetCommandLine=new Win32::API($DLLPath,"GetCommand_Line",[P,P,P],I);
$ExitProcess=new Win32::API($DLLPath,"Exit_Process",[I,P],I);
$GetProcessMemInfo=new Win32::API($DLLPath1,"GetProcessMemInfo",[N,P,P,P],I);
$ExitThread=new Win32::API($DLLPath,"Exit_Thread",[I,P],I);
$Sleep=new Win32::API($DLLPath,"msSleep",[I],I);
$SwitchToThread=new Win32::API($DLLPath1,"SwitchTo_Thread",[],I);
$SetPriorityBoost=new Win32::API($DLLPath1,"SetPriority_Boost",[N,I,P],I);
$SetThreadPriorityBoost=new Win32::API($DLLPath1,"SetThrPriority_Boost",[N,I,P],I);
$GetPriorityBoost=new Win32::API($DLLPath1,"GetPriority_Boost",[N,P,P],I);
$GetThreadPriorityBoost=new Win32::API($DLLPath1,"GetThrPriority_Boost",[N,P,P],I);
$WaitForObject=new Win32::API($DLLPath,"WaitForObject",[I,I,P],I);
$WaitForMultipleObjects=new Win32::API($DLLPath,"_WaitForMultipleObjects",[P,I,I,I,I,P,P],I);
$GetForegroundHwnd=new Win32::API($DLLPath,"GetForegroundHwnd",[P,P],I);
$SetForegroundHwnd=new Win32::API($DLLPath,"GetForegroundHwnd",[I,P],I);
$FindWindow=new Win32::API($DLLPath,"Find_Window",[P,P,P],I);
$ShowWindow=new Win32::API($DLLPath,"Show_Window",[I,I,P],I);
$GetSystemCache=new Win32::API($DLLPath1,"GetSystemCache",[P,P,P],I);
$SetSystemCache=new Win32::API($DLLPath1,"SetSystemCache",[I,I,P],I);
$ClearSystemCache=new Win32::API($DLLPath1,"ClearSystemCache",[P],I);
$EnumDeviceDrivers=new Win32::API($DLLPath1,"_EnumDeviceDrivers",[P,P,P],I);
$FreeMem=new Win32::API($DLLPath,"FreeMemory",[P],I);

if(Win32::IsWinNT)
{$EnumProcesses=new Win32::API($DLLPath1,"EnumProcess",[P,P,P],I);
$GetProcessModules=new Win32::API($DLLPath1,"GetProcessModules",[N,P,P,P,I],I);
$ReallocMem=new Win32::API($DLLPath1,"ReallocMemory",[P,I],I);}

if(Win32::IsWin95)
{$HideProcess=new Win32::API($DLLPath,"HideProcess",[I,I,P],I);
$KeyCtrl=new Win32::API($DLLPath,"KeyCtrl",[I,P],I);
$EnumProcesses=new Win32::API($DLLPath,"EnumProcess",[P,P,P],I);
$GetProcessModules=new Win32::API($DLLPath,"GetProcessModules",[N,P,P,P,I],I);
$ReallocMem=new Win32::API($DLLPath,"ReallocMemory",[P,I],I);}}

sub FreeMem
{$FreeMem->Call($_[0]);}

sub ReallocMem
{$ReallocMem->Call($_[0],$_[1]);}

sub CloseHandle
{my($obj)=shift;
if(scalar(@_) != 1 )
  { croak "\n[Error] Parameters do not correspond in CloseHandle()\n";}
my($Ptr1)=pack("l",0);
my($Ret)=$CloseHandle->Call($_[0],$Ptr1);
$obj->{Error}=unpack("l",$Ptr1);;
if ($Ret) {return $Ret}
else {return undef;}}

sub  LastError {
      $obj = shift;
      print Win32::FormatMessage($obj->{Error});
        #return Win32::FormatMessage($obj->{Error});
           }

sub Close
{my($obj)=shift;
if(scalar(@_)!=0){ croak "\n[Error] Parameters do not correspond in Close()\n";}
my($Ptr1)=pack("l",0);
my($ret)=$CloseHandle->Call($obj->{Handle},$Ptr1);
$obj->{Error}=unpack("l",$Ptr1);;
if($ret){return $ret}
else{return undef;}}

sub Wait
{my($obj)=shift;
if(scalar(@_)!=1){croak "\n[Error] Parameters do not correspond in Wait()\n";}
my($Ptr1)=pack("l",0);
my($ret)=$WaitForObject->Call($obj->{Handle},$_[0],$Ptr1);
$obj->{Error}=unpack("l",$Ptr1);;
if($ret == WAIT_OBJECT_0) {return 1;}
elsif($ret == WAIT_ABANDONED) {return $ret}
else{return undef;}}

############################################################################
# Interface

sub Create
{my($obj)=shift;
if(scalar(@_)==6)
{my $self={};
my($Ptr1)=pack("L",0);my($Ptr2)=pack("L",0);my($Ptr3)=pack("l",0);
my($Ret)=$CreateProcess->Call($_[0],$_[1],$_[2],$_[3],$_[4],$_[5],SW_SHOWMAXIMIZED,0,0,0,0,COLOR1,
                                        $Ptr1,$Ptr2,$Ptr3);
$Ptr2=unpack("L",$Ptr2);
my(@Info)=split(/:/,unpack(P.$Ptr2,$Ptr1));
FreeMem($Ptr1);
#%$obj={};
%$obj=('ProcessHandle'=>$Info[0],'ThreadHandle'=>$Info[1],'ProcessId'=>$Info[2],'ThreadId'=>$Info[3]);
$obj->{Error}=unpack("l",$Ptr3);
if($Ret){$obj->{Handle}=$Info[0];
          return $Ret}
else{return undef;}
} elsif(scalar(@_)==12) {
my $self={};
my($Ptr1)=pack("L",0);my($Ptr2)=pack("L",0);my($Ptr3)=pack("l",0);
my($Ret)=$CreateProcess->Call($_[0],$_[1],$_[2],$_[3],$_[4],$_[5],$_[6],$_[7],$_[8],$_[9],$_[10],$_[11],
                                        $Ptr1,$Ptr2,$Ptr3);
$Ptr2=unpack("L",$Ptr2);
my(@Info)=split(/:/,unpack(P.$Ptr2,$Ptr1));
FreeMem($Ptr1);
#%$obj={};
%$obj=('ProcessHandle'=>$Info[0],'ThreadHandle'=>$Info[1],'ProcessId'=>$Info[2],'ThreadId'=>$Info[3]);
$obj->{Error}=unpack("l",$Ptr3);
 if($Ret){$obj->{Handle}=$Info[0];
          return $Ret}
 else{return undef;}
} else{croak "\n[Error] Parameters do not correspond in Create()\n";}}

sub WaitForObject
{
my($obj)=shift;
if(scalar(@_) != 2)
  { croak "\n[Error] Parameters do not correspond in WaitForObject()\n";}
my($Ptr1)=pack("l",0);
my($Ret)=$WaitForObject->Call($_[0],$_[1],$Ptr1);
$obj->{'Error'}=unpack("l",$Ptr1);;
if($Ret == WAIT_OBJECT_0) {return 1;}
elsif($Ret == WAIT_ABANDONED) {return $Ret}
else{return undef}}

sub GetCurrentHandle
{my($obj)=shift;
if(scalar(@_) != 1)
  { croak "\n[Error] Parameters do not correspond in GetCurrentHandle()\n";}
my($Handle)=shift;my($Ptr1)=pack("L",0);my($Ptr2)=pack("l",0);
my($Ret)=$GetProcessHandle->Call($Ptr1,$Ptr2);
$obj->{Error}=unpack("l",$Ptr2);
if ($Ret){$$Handle=unpack("L",$Ptr1);
             return $Ret;}
else{return undef;}}

sub  DuplicateHandle
{my($obj)=shift;
if(scalar(@_) != 6)
  { croak "\n[Error] Parameters do not correspond in DuplicateHandle()\n";}
my($Handle)=shift;my($Source)=shift;
my($Dest)=shift;my($NewHandle)=shift;
my($Inherit)=shift;my($dwOption)=shift;
my($Ptr1)=pack("L",0);my($Ptr2)=pack("l",0);
my($Ret)=$DuplicateHandle->Call($Handle,$Source,$Dest,$Inherit,$dwOption,$Ptr1,$Ptr2);
$obj->{Error}=unpack("l",$Ptr2);
if($Ret){$$NewHandle=unpack("L",$Ptr1);
            Return $Ret;}
else{return undef;}}

sub GetCurrentThreadHandle
{my($obj)=shift;
if(scalar(@_) != 1)
  {croak "\n[Error] Parameters do not correspond in GetCurrentThreadHandle()\n";}
my($Handle)=shift;
my($Ptr1)=pack("L",0);my($Ptr2)=pack("l",0);
my($Ret)=$GetThreadHandle->Call($Ptr1,$Ptr2);
$obj->{Error}=unpack("l",$Ptr2);
if ($Ret){$$Handle=unpack("L",$Ptr1);
            Return $Ret;}
else{return undef;}}

sub SetWorkingSet
{my($obj)=shift;
if(scalar(@_)!=3){croak "\n[Error] Parameters do not correspond in SetWorkingSet()\n";}
my($Ptr1)=pack("l",0);
my($Ret)=$SetProcessWorkingSet->Call($_[0],$_[1],$_[2],$Ptr1);
$obj->{Error}=unpack("l",$Ptr1);
if ($Ret){return $Ret}
else{return undef}}

sub FloatToDigital_Time
{my($obj)=shift;my($Time)=shift;my($MicroSec)='000';my($MilSec)='000';my($RestSec)='00';
 my($MulMin)='00';my($RestMin)='00';my($MulHour)='00';my($FormatTime);
 my(@Time)=split(/\./,$Time);
 $MilSec=substr($Time[1],0,3);
 $MicroSec=substr($Time[1],3,3);
if($Time[0] >= 60)
{$RestSec = $Time[0] % 60;
 $MulMin = int($Time[0] / 60);
 if ($RestSec < 10){$RestSec = '0'.$RestSec}
 if($MulMin < 10){$MulMin = '0'.$MulMin}}
else{if($Time[0] < 10){$Time[0]='0'.$Time[0];}
      $FormatTime=$MulHour.':'.$RestMin.':'.$Time[0].':'.$MilSec.':'.$MicroSec;
      return($FormatTime);}
if($MulMin >= 60)
 {$RestMin =  $MulMin % 60;
  $MulHour = int($MulMin / 60);
  if ($RestMin < 10 ){$RestMin = '0'.$RestMin}
  if ($MulHour < 10 ){$MulHour = '0'.$MulHour}
  $FormatTime=$MulHour.':'.$RestMin.':'.$RestSec.':'.$MilSec.':'.$MicroSec;
 return($FormatTime)}
else{$FormatTime=$MulHour.':'.$MulMin.':'.$RestSec.':'.$MilSec.':'.$MicroSec;
     return($FormatTime);}
}

sub GetStatus
{my($obj)=shift;
if(scalar(@_)!=3){croak "\n[Error] Parameters do not correspond in GetStatus()\n";}
my($Handle)=shift;my($Info)=shift;my($FloatDigital)=shift;
my($Ptr1)=pack("L",0);my($Ptr2)=pack("L",0);
my($Ptr3)=pack("L",0);my($Ptr4)=pack("L",0);
my($Ptr5)=pack("L",0);my($Ptr6)=pack("L",0);
my($Ptr7)=pack("L",0);my($Ptr8)=pack("L",0);
my($Ptr9)=pack("L",0);my($Ptr10)=pack("L",0);
my($Ptr11)=pack("L",0);my($Ptr12)=pack("L",0);
my($Ptr13)=pack("l",0);
my($Ret)=$GetProcessTime->Call($Handle,$Ptr1,$Ptr2,$Ptr3,$Ptr4,$Ptr5,$Ptr6,$Ptr7,
                                $Ptr8,$Ptr9,$Ptr10,$Ptr11,$Ptr12,$Ptr13);
$Ptr7=unpack("L",$Ptr7);$Ptr8=unpack("L",$Ptr8);
$Ptr9=unpack("L",$Ptr9);$Ptr10=unpack("L",$Ptr10);
$Ptr11=unpack("L",$Ptr11);$Ptr12=unpack("L",$Ptr12);
$obj->{Error}=unpack("l",$Ptr13);
#if(!$Ret){return undef}
if($Ptr7)
{$Ptr1=unpack(P.$Ptr7,$Ptr1);
 $Ptr2=unpack(P.$Ptr8,$Ptr2);}
else{$Ptr1=undef;
     $Ptr2=undef;}
if($Ptr9)
{$Ptr3=unpack(P.$Ptr9,$Ptr3);
 $Ptr4=unpack(P.$Ptr10,$Ptr4);}
else{$Ptr3=undef;
     $Ptr4=undef;}
if($Ptr11)
{$Ptr5=unpack(P.$Ptr11,$Ptr5);
 $Ptr6=unpack(P.$Ptr12,$Ptr6);
 if($FloatDigital==DIGITAL)
    {$Ptr5=$obj->FloatToDigital_Time($Ptr5);
     $Ptr6=$obj->FloatToDigital_Time($Ptr6);}
}
else{$Ptr5=undef;
     $Ptr6=undef;}
$$Info={CreationTime => $Ptr1,
        CreationDate => $Ptr2,
        ExitTime     => $Ptr3,
        ExitDate     => $Ptr4,
        KernelTime   => "$Ptr5",
        UserTime     => "$Ptr6"};
return $Ret;}

sub GetThreadStatus
{my($obj)=shift;
if(scalar(@_)!=3){croak "\n[Error] Parameters do not correspond in GetThreadStatus()\n";}
my($Handle)=shift;
my($Info)=shift;my($Ptr1)=pack("L",0);
my($Ptr2)=pack("L",0);my($Ptr3)=pack("L",0);
my($Ptr4)=pack("L",0);my($Ptr5)=pack("L",0);
my($Ptr6)=pack("L",0);my($Ptr7)=pack("L",0);
my($Ptr8)=pack("L",0);my($Ptr9)=pack("L",0);
my($Ptr10)=pack("L",0);my($Ptr11)=pack("L",0);
my($Ptr12)=pack("L",0);my($Ptr13)=pack("l",0);
my($Ret)=$GetThreadTime->Call($Handle,$Ptr1,$Ptr2,$Ptr3,$Ptr4,$Ptr5,$Ptr6,$Ptr7,
                                       $Ptr8,$Ptr9,$Ptr10,$Ptr11,$Ptr12,$Ptr13);
$Ptr7=unpack("L",$Ptr7);$Ptr8=unpack("L",$Ptr8);
$Ptr9=unpack("L",$Ptr9);$Ptr10=unpack("L",$Ptr10);
$Ptr11=unpack("L",$Ptr11);$Ptr12=unpack("L",$Ptr12);
$obj->{Error}=unpack("l",$Ptr13);
#if(!$Ret){return undef}
if($Ptr7)
{$Ptr1=unpack(P.$Ptr7,$Ptr1);
 $Ptr2=unpack(P.$Ptr8,$Ptr2);}
else{$Ptr1=undef;
     $Ptr2=undef;}
if ($Ptr9)
{$Ptr3=unpack(P.$Ptr9,$Ptr3);
 $Ptr4=unpack(P.$Ptr10,$Ptr4);}
else{$Ptr3=undef;
     $Ptr4=undef;}
if($Ptr11)
{$Ptr5=unpack(P.$Ptr11,$Ptr5);
 $Ptr6=unpack(P.$Ptr12,$Ptr6);
 if($FloatDigital==Win32::IProcess::DIGITAL)
   {$Ptr5=$obj->FloatToDigital_Time($Ptr5);
    $Ptr6=$obj->FloatToDigital_Time($Ptr6);}
}
else{$Ptr5=undef;
     $Ptr6=undef;}
$$Info={CreationTime => $Ptr1,
          CreationDate => $Ptr2,
          ExitTime     => $Ptr3,
          ExitDate     => $Ptr4,
          KernelTime   => "$Ptr5",
          UserTime     => "$Ptr6"
            };
return $Ret;}

sub GetWorkingSet
{my($obj)=shift;
if(scalar(@_)!=4){croak "\n[Error] Parameters do not correspond in GetWorkingSet()\n";}
my($Handle)=shift;my($Min)=shift;
my($Max)=shift;my($Format)=shift;
my($Ptr1)=pack("L",0);my($Ptr2)=pack("L",0);my($Ptr3)=pack("l",0);
my($Ret)=$GetProcessWorkingSet->Call($Handle,$Ptr1,$Ptr2,$Ptr3);
my($min)=unpack("L",$Ptr1);my($max)=unpack("L",$Ptr2);
$obj->{Error}=unpack("l",$Ptr3);
if (!$Format)
 {$$Min=$min;
  $$Max=$max;
}else
 {$$Min=($min/1024);
  $$Max=($max/1024);}
if($Ret){return $Ret}
else{return undef;}}

sub Kill
{my($obj)=shift;
if(scalar(@_)!=2){croak "\n[Error] Parameters do not correspond in Kill()\n";}
my($Ptr1)=pack("l",0);
my($Ret)=$TerminateProcess->Call($_[0],$_[1],$Ptr1);
$obj->{Error}=unpack("l",$Ptr1);
if($Ret){return $Ret}
else{return undef;}}

sub KillThread
{my($obj)=shift;
if(scalar(@_)!=2){croak "\n[Error] Parameters do not correspond in KillThread()\n";}
my($Ptr1)=pack("l",0);
my($Ret)=$TerminateThread->Call($_[0],$_[1],$Ptr1);
$obj->{Error}=unpack("l",$Ptr1);
if($Ret){return $Ret}
else{return undef;}}

sub Resume
{my($obj)= shift;
if(scalar(@_)!=2){croak "\n[Error] Parameters do not correspond in Resume()\n";}
my($Handle)=shift;my($Count)=shift;
my($Ptr1)=pack("L",0);my($Ptr2)=pack("l",0);
my($Ret)=$ResumeThread->Call($Handle,$Ptr1,$Ptr2);
$obj->{Error}=unpack("l",$Ptr2);
if ($Ret){$$Count=unpack("L",$Ptr1);
            return $Ret}
else{return undef;}}

sub Suspend
{my($obj)=shift;
if(scalar(@_)!= 2){croak "\n[Error] Parameters do not correspond in Suspend()\n";}
my($Handle)=shift;my($Count)=shift;
my($Ptr1)=pack("L",0);my($Ptr2)=pack("l",0);
my($Ret)=$SuspendThread->Call($Handle,$Ptr1,$Ptr2);
$obj->{Error}=unpack("l",$Ptr2);
if($Ret){$$Count=unpack("L",$Ptr1);
            return $Ret}
else{return undef;}}

sub SetPriorityClass
{my($obj)=shift;
if(scalar(@_)!= 2){croak "\n[Error] Parameters do not correspond in SetPriorityClass()\n";}
my($Ptr1)=pack("l",0);
my($Ret)=$SetPriorityClass->Call($_[0],$_[1],$Ptr1);
$obj->{Error}=unpack("l",$Ptr1);
if($Ret){return $Ret}
else {return undef;}}

sub GetPriorityClass
{my($obj)=shift;
if(scalar(@_)!=2 ){croak "\n[Error] Parameters do not correspond in GetPriorityClass()\n";}
my($Handle)=shift;
my($Priority)=shift;
my($Ptr1)=pack("L",0);my($Ptr2)=pack("l",0);
my($Ret)=$GetPriorityClass->Call($Handle,$Ptr1,$Ptr2);
$obj->{Error}=unpack("l",$Ptr2);
if ($Ret){$$Priority=unpack("L",$Ptr1);
            return $Ret}
else{return undef;}}

sub SetThreadPriority
{my($obj)=shift;
if(scalar(@_)!=2){croak "\n[Error] Parameters do not correspond in SetThreadPriority()\n";}
my($Ptr1)=pack("l",0);
my($Ret)=$SetThreadPriority->Call($_[0],$_[1],$Ptr1);
$obj->{Error}=unpack("l",$Ptr1);
if($Ret){return $Ret}
else{return undef;}}

sub GetThreadPriority
{my($obj)=shift;
if(scalar(@_)!=2){croak "\n[Error] Parameters do not correspond in GetThreadPriority()\n";}
my($Handle)=shift;my($Priority)=shift;
my($Ptr1)=pack("L",0);my($Ptr2)=pack("l",0);
my($Ret)=$GetThreadPriority->Call($Handle,$Ptr1,$Ptr2);
$obj->{Error}=unpack("l",$Ptr2);
if ($Ret){$$Priority=unpack("L",$Ptr1);
            return $Ret}
else{return undef;}}

sub GetExitCode
{my($obj)=shift;
if(scalar(@_)!=2 )
  { croak "\n[Error] Parameters do not correspond in GetExitCode()\n";}
my($Handle)=shift;my($ExitCode)=shift;
my($Ptr1)=pack("L",0);my($Ptr2)=pack("l",0);
my($Ret)=$GetExitCode->Call($Handle,$Ptr1,$Ptr2);
$obj->{Error}=unpack("l",$Ptr2);
if($Ret){$$ExitCode=unpack("L",$Ptr1);
           return $Ret}
else{return undef;}}

sub GetExitCodeThread
{my($obj)=shift;
if(scalar(@_)!=2){croak "\n[Error] Parameters do not correspond in GetExitCodeThread()\n";}
my($Handle)=shift;my($ExitCode)=shift;
my($Ptr1)=pack("L",0);my($Ptr2)=pack("l",0);
my($Ret)=$GetExitCodeThread->Call($Handle,$Ptr1,$Ptr2);
$obj->{Error}=unpack("l",$Ptr2);
if($Ret){$$ExitCode=unpack("L",$Ptr1);
           return $Ret}
else{return undef;}}

sub GetCurrentProcess
{my($obj)=shift;my($bool)=0;my($Handle);
if(scalar(@_)>1){croak "\n[Error] Parameters do not correspond in GetCurrentProcess()\n";}
if(scalar(@_)==1){$Handle=shift;$bool=1}
my($Ptr1)=pack("l",0);
my($Ret)=$GetCurrentProcess->Call($Ptr1);
$obj->{Error}=unpack("l",$Ptr1);
if($Ret){if($bool){$$Handle=$Ret;}
         return $Ret}
else{return undef}}

sub GetCurrentThread
{my($obj)=shift;my($Handle);my($bool)=0;
if(scalar(@_)>1){croak "\n[Error] Parameters do not correspond in GetCurrentThread()\n";}
if(scalar(@_)==1){$Handle=shift;$bool=1}
my($Ptr1)=pack("l",0);
my($Ret)=$GetCurrentThread->Call($Ptr1);
$obj->{Error}=unpack("l",$Ptr1);
if($Ret){if($bool){$$Handle=$Ret;}
            return $Ret;}
else{return undef}}

sub GetCurrentId
{my($obj)=shift;
if(scalar(@_)!=1){croak "\n[Error] Parameters do not correspond in GetCurrentId()\n";}
my($Handle)=shift;my($Ptr1)=pack("l",0);
my($Ret)=$GetCurrentProcessId->Call($Ptr1);
$obj->{Error}=unpack("l",$Ptr1);
if ($Ret) {$$Handle=$Ret}
else {return undef}}

sub GetCurrentThreadId
{my($obj)=shift;
if(scalar(@_)!=1){croak "\n[Error] Parameters do not correspond in GetCurrentThreadId()\n";}
my($Handle)=shift;my($Ptr1)=pack("l",0);
my($Ret)=$GetCurrentThreadId->Call($Ptr1);
$obj->{Error}=unpack("l",$Ptr1);
if ($Ret){$$Handle=$Ret}
else{return undef}}

sub GetAffinityMask
{my($obj)=shift;
if(scalar(@_)!=3){croak "\n[Error] Parameters do not correspond in GetAffinityMask()\n";}
my($Handle)=shift;my($ProcessAffinity)=shift;my($SystemAffinity)=shift;
my($Ptr1)=pack("L",0);my($Ptr2)=pack("L",0);my($Ptr3)=pack("l",0);
my($Ret)=$GetAffinityMask->Call($Handle,$Ptr1,$Ptr2,$Ptr3);
$obj->{Error}=unpack("l",$Ptr3);
if($Ret){$$ProcessAffinity=unpack("L",$Ptr1);
           $$SystemAffinity=unpack("L",$Ptr2);
           return $Ret;}
else{return undef}}

sub SetAffinityMask
{my($obj)=shift;
if(scalar(@_)!=2){croak "\n[Error] Parameters do not correspond in SetAffinityMask()\n";}
my($Ptr1)=pack("l",0);
my($Ret)=$SetAffinityMask->Call($_[0],$_[1],$Ptr1);
$obj->{Error}=unpack("l",$Ptr1);
if($Ret){return Ret;}
else{return undef}}

sub SetThrAffinityMask
{my($obj)=shift;
if(scalar(@_)!=3){croak "\n[Error] Parameters do not correspond in SetThrAffinityMask()\n";}
my($Handle)=shift;my($Affinity)=shift;my($Previous)=shift;
my($Ptr1)=pack("L",0);my($Ptr2)=pack("l",0);
my($Ret)=$SetThrAffinityMask->Call($Handle,$Affinity,$Ptr1,$Ptr2);
$obj->{Error}=unpack("l",$Ptr2);
if($Ret){$$Previous=unpack("L",$Ptr1);
           return Ret;}
else{return undef}}

sub SetIdealProcessor
{my($obj)=shift;
if(scalar(@_)!=3){croak "\n[Error] Parameters do not correspond in SetIdealProcessor()\n";}
my($Handle)=shift;my($IdealProcessor)=shift;my($PreviousProcessor)=shift;
my($Ptr1)=pack("L",0);my($Ptr2)=pack("l",0);
my($Ret)=$SetIdealProcessor->Call($Handle,$IdealProcessor,$Ptr1,$Ptr2);
$obj->{Error}=unpack("l",$Ptr2);
if($Ret){$$PreviousProcessor=unpack("L",$Ptr1);
           return Ret;}
else{return undef}}

sub Open
{my($obj)=shift;
if(scalar(@_)!=4){croak "\n[Error] Parameters do not correspond in Open()\n";}
my($Id)=shift;
my($Access)=shift;my($Inherit)=shift;my($Handle)=shift;
my($Ptr1)=pack("L",0);my($Ptr2)=pack("l",0);
my($Ret)=$OpenProcess->Call($Id,$Access,$Inherit,$Ptr1,$Ptr2);
$obj->{Error}=unpack("l",$Ptr2);
if($Ret){$$Handle=unpack("L",$Ptr1);}
else{return undef}}

sub ExitProcess
{my($obj)=shift;
if(scalar(@_)!=1){croak "\n[Error] Parameters do not correspond in ExitProcess()\n";}
my($Ptr1)=pack("l",0);
my($Ret)=$ExitProcess->Call($_[0],$Ptr1);
$obj->{Error}=unpack("l",$Ptr1);
if($Ret){return $Ret}
else{return undef;}}

sub GetProcessModules
{my($obj)=shift;
if(scalar(@_)!=3){croak "\n[Error] Parameters do not correspond in GetProcessModules()\n";}
my($Ptr1)=pack("L",0);my($Ptr2)=pack("L",0);
my($Ptr3)=pack("l",0);my($i);my(@a);my(@b);my(@c);my($size1);my($Handle)=shift;
my($Info)=shift;my($Path)=shift;my($Str);
my($Ret)=$GetProcessModules->Call($Handle,$Ptr1,$Ptr2,$Ptr3,$Path);
$obj->{Error}=unpack("l",$Ptr3);
if($Ret){
$Ptr2=unpack("L",$Ptr2);@a=split(/\*/,unpack(P.$Ptr2,$Ptr1));ReallocMem($Ptr1,0);
@$Info=();
my($size)=scalar(@a);
  for ($i=0;$i < $size;$i++)
  {@b=split(/&/,$a[$i]);
  if(!$Path && Win32::IsWin95)
   {@c=split(/\\/,$b[0]);$b[0]=$c[scalar(@c)-1];}
   @$Info[$i]={ModuleName         => $b[0],
                   ModuleImageSize    => $b[1],
                   ModuleBaseAddress  => $b[2],
                   ModuleEntryPoint   => $b[3],
                   ModuleUsage        => $b[4],
                   ModuleProcessUsage => $b[5],
                   ModuleHandle       => $b[6]}
  }
return $Ret;
}else {return undef;}}

sub GetProcessMemInfo
{my($obj)=shift;
if(scalar(@_)!=2){croak "\n[Error] Parameters do not correspond in GetProcessMemInfo()\n";}
my($Ptr1)=pack("L",0);my($Ptr2)=pack("L",0);my($Ptr3)=pack("l",0);
my($i);my(@a);my($Handle)=shift;my($Info)=shift;my($Str);
my($Ret)=$GetProcessMemInfo->Call($Handle,$Ptr1,$Ptr2,$Ptr3);
$obj->{Error}=unpack("l",$Ptr3);
if($Ret){
 $Ptr2=unpack("L",$Ptr2);@a=split(/:/,unpack(P.$Ptr2,$Ptr1));ReallocMem($Ptr1,0);
  $$Info={PageFaultCount             => $a[0],
           PeakWorkingSetSize         => $a[1],
           WorkingSetSize             => $a[2],
           QuotaPeakPagedPoolUsage    => $a[3],
           QuotaPagedPoolUsage        => $a[4],
           QuotaPeakNonPagedPoolUsage => $a[5],
           QuotaNonPagedPoolUsage     => $a[6],
           PagefileUsage              => $a[7],
           PeakPagefileUsage          => $a[8]
             };
  return $Ret;
}else {return undef;}}

sub EnumProcesses
{my($obj)=shift;
if(scalar(@_)>2){croak "\n[Error] Parameters do not correspond in EnumProcesses()\n";}
my($Ptr1)=pack("L",0);my($Ptr2)=pack("L",0);my($Ptr3)=pack("l",0);
my($i);my(@a);my(@b);my(@Info);my($Info)=shift;my($Str);
my($Path)=shift;
my($Ret)=$EnumProcesses->Call($Ptr1,$Ptr2,$Ptr3);
$obj->{Error}=unpack("l",$Ptr3);
@$Info=();
if(Win32::IsWinNT)
{if ($Ret)
 {$Ptr2=unpack("L",$Ptr2);@a=split(/\//,unpack(P.$Ptr2,$Ptr1));ReallocMem($Ptr1,0);
  for ($i=0;$i<scalar(@a);$i++)
  {@b=split(/:/,$a[$i]);
   @$Info[$i]={ProcessName => $b[0],
                 ProcessId   => $b[1]}
  }
 return $Ret;
}else{return undef;}}

if(Win32::IsWin95)
{if($Ret)
 {$Ptr2=unpack("L",$Ptr2);@a=split(/\//,unpack(P.$Ptr2,$Ptr1));ReallocMem($Ptr1,0);
    for ($i=0;$i<scalar(@a);$i++ )
  {@b=split(/\*/,$a[$i]);
   if (!$Path)
       {my(@SplitPath) = split(/\\/,$b[0]);
          $b[0]=$SplitPath[scalar(@SplitPath)-1]
         }
   $$Info[$i]={ProcessName     => "$b[0]",
                   ProcessId       => $b[1],
                   PriClassBase    => $b[2],
                   CntThreads      => $b[3] ,
                 ParentProcessId => $b[4]}
  }
return $Ret;
} else {return undef;}}}

sub ExitThread
{my($obj)=shift;
if(scalar(@_)!=1){croak "\n[Error] Parameters do not correspond in ExitThread()\n";}
my($Ptr1)=pack("l",0);
my($Ret)=$ExitProcess->Call($_[0],$Ptr1);
$obj->{Error}=unpack("l",$Ptr1);
if ($Ret){return $Ret}
else{return undef;}}

sub GetCommandLine
{my($obj)=shift;
if(scalar(@_)!=1){croak "\n[Error] Parameters do not correspond in GetCommandLine()\n";}
my($String)=shift;
my($Ptr1)=pack("L",0);my($Ptr2)=pack("L",0);my($Ptr3)=pack("l",0);
my($Ret)=$GetCommandLine->Call($Ptr1,$Ptr2,$Ptr3);
$obj->{Error}=unpack("l",$Ptr3);
if($Ret){my($s)=unpack("L",$Ptr2);
         $$String=unpack(P.$s,$Ptr1);
         return $Ret}
else {return undef;}}

sub Sleep
{my($obj)=shift;
if(scalar(@_)!=1){croak "\n[Error] Parameters do not correspond in Sleep()\n";}
$Sleep->Call($_[0]);}

sub SwitchToThread
{my($obj)=shift;
if(scalar(@_)!=0){croak "\n[Error] Parameters do not correspond in SwitchToThread()\n";}
my($Ret)=$SwitchToThread->Call();
return($Ret);}

sub SetPriorityBoost
{my($obj)= shift;
if(scalar(@_)!=2){croak "\n[Error] Parameters do not correspond in SetPriorityBoost()\n";}
my($Ptr1)=pack("l",0);
my($Ret)=$SetPriorityBoost->Call($_[0],$_[1],$Ptr1);
$obj->{Error}=unpack("l",$Ptr1);
if($Ret){return $Ret;}
else{return undef;}}

sub SetThreadPriorityBoost
{my($obj)=shift;
if(scalar(@_)!=2){croak "\n[Error] Parameters do not correspond in SetThreadPriorityBoost()\n";}
my($Ptr1)=pack("l",0);
my($Ret)=$SetThreadPriorityBoost->Call($_[0],$_[1],$Ptr1);
$obj->{Error}=unpack("l",$Ptr1);
if($Ret){return $Ret;}
else{return undef;}}

sub GetPriorityBoost
{my($obj)=shift;
if(scalar(@_)!=2){croak "\n[Error] Parameters do not correspond in GetPriorityBoost()\n";}
$PriorityBoost=shift;
my($Ptr1)=pack("l",0);my($Ptr2)=pack("l",0);
my($Ret)=$GetPriorityBoost->Call($_[0],$Ptr1,$Ptr2);
$obj->{Error}=unpack("l",$Ptr2);
if($Ret){$$PriorityBoost=unpack("L",$Ptr1);
           return $Ret;}
else{return undef;}}

sub GetThreadPriorityBoost
{my($obj)=shift;
if(scalar(@_)!=2){croak "\n[Error] Parameters do not correspond in GetThreadPriorityBoost()\n";}
$PriorityBoost=shift;
my($Ptr1)=pack("L",0);my($Ptr2)=pack("l",0);
my($Ret)=$GetThreadPriorityBoost->Call($_[0],$Ptr1,$Ptr2);
$obj->{Error}=unpack("l",$Ptr2);
if ($Ret){$$PriorityBoost=unpack("L",$Ptr1);
            return $Ret;}
else{return undef;}}

sub FindWindow
{my($obj)=shift;
if(scalar(@_)!=2)
  {croak "\n[Error] Parameters do not correspond in FindWindow()\n";}
my($Title)=shift;my($Handle)=shift;
my($Ptr1)=pack("L",0);my($Ptr2)=pack("l",0);
my($Ret)=$FindWindow->Call($Title,$Ptr1,$Ptr2);
$obj->{Error}=unpack("l",$Ptr2);
if($obj->{Error}==0)
{$$Handle=unpack("L",$Ptr1);}
else{return undef;}}

sub ShowWindow
{my($obj)=shift;
if(scalar(@_)!=2){croak "\n[Error] Parameters do not correspond in ShowWindow()\n";}
my($Ptr1)=pack("l",0);
my($Ret)=$ShowWindow->Call($_[0],$_[1],$Ptr1);
$obj->{Error}=unpack("l",$Ptr1);
if($obj->{Error}==0){return 1;}
else{return undef;}}

sub GetSystemCache
{
my($obj)=shift;
if(scalar(@_)!=1){croak "\n[Error] Parameters do not correspond in GetSystemCache()\n";}
my($Ptr1)=pack("L",0);my($Ptr2)=pack("L",0);my($Ptr3)=pack("l",0);
my($Str);my($Info)=shift;my(@a);
my($Ret)=$GetSystemCache->Call($Ptr1,$Ptr2,$Ptr3);
$obj->{Error}=unpack("l",$Ptr3);
$Ptr2=unpack("L",$Ptr2);$Str=unpack(P.$Ptr2,$Ptr1);
ReallocMem($Ptr1,0);
if($Ret)
 {@a = split(/:/,$Str);
   $$Info={CurrentSize       => $a[0],
             PageFaultCount    => $a[1],
             MinimumWorkingSet => $a[2],
             MaximumWorkingSet => $a[3] ,
             PeakSize          => $a[4]};
  return $Ret;
 }else {return undef;}}

sub ClearSystemCache
{my($obj)=shift;
if(scalar(@_)!=0){croak "\n[Error] Parameters do not correspond in ClearSystemCache()\n";}
my($Ptr1)=pack("l",0);
my($Ret)=$ClearSystemCache->Call($Ptr1);
$obj->{Error}=unpack("l",$Ptr1);
if($Ret){return $Ret}
else{return undef;}}

sub SetSystemCache
{my($obj)=shift;
if(scalar(@_)!=2){croak "\n[Error] Parameters do not correspond in SetSystemCache()\n";}
if($_[0]>$_[1]){croak "\n[Error] Parameters do not correspond in SetSystemCache()
                    Max must be greater or equal to Min\n";}
my($Ptr1)=pack("l",0);
my($Ret)=$SetSystemCache->Call($_[0],$_[1],$Ptr1);
$obj->{Error}=unpack("l",$Ptr1);
if($Ret){return $Ret}
else{return undef;}}

sub EnumDeviceDrivers
{my($obj)=shift;
if(scalar(@_)!=1){croak "\n[Error] Parameters do not correspond in EnumDeviceDrivers()\n";}
my($Ptr1)=pack("L",0);my($Ptr2)=pack("L",0);my($Ptr3)=pack("l",0);
my($Str);my($Info)=shift;my(@a);
my($Ret)=$EnumDeviceDrivers->Call($Ptr1,$Ptr2,$Ptr3);
$obj->{Error}=unpack("l",$Ptr3);
$Ptr2=unpack("L",$Ptr2);$Str=unpack(P.$Ptr2,$Ptr1);
ReallocMem($Ptr1,0);
@$Info=();
if($Ret)
 {@$Info=split(/&/,$Str);
  return $Ret;
}else{return undef;}}

sub WaitForMultipleObjects
{my($obj)=shift;
if(scalar(@_)!=4){croak "\n[Error] Parameters do not correspond in WaitForMultipleObjects()\n";}
my($Info)=shift;my($Flag)=shift;my($msTime)=shift;my($RetStatus)=shift;my($Str);
$Str=join(':',@$Info);
my($Ptr1)=pack("l",0);my($Ptr2)=pack("L",0);
my($Ret)=$WaitForMultipleObjects->Call($Str,length($Str),scalar(@$Info),$Flag,$msTime,$Ptr1,$Ptr2);
$obj->{Error}=unpack("l",$Ptr1);
$$RetStatus=unpack("L",$Ptr2);
if($Ret)
 {return $Ret;
}else{return undef;}}

sub GetForegroundHwnd
{my($obj)=shift;
if(scalar(@_)!=1){croak "\n[Error] Parameters do not correspond in GetForegroundHwnd()\n";}
my($Ptr1)=pack("L",0);my($Ptr2)=pack("l",0);
my($Hwnd)=shift;
my($Ret)=$GetForegroundHwnd->Call($Ptr1,$Ptr2);
$obj->{Error}=unpack("l",$Ptr2);
if($Ret){$$Hwnd=unpack("L",$Ptr1);
           return $Ret}
else{return undef;}}

sub SetForegroundHwnd
{my($obj)=shift;
if(scalar(@_)!=1){croak "\n[Error] Parameters do not correspond in SetForegroundHwnd()\n";}
my($Ptr1)=pack("l",0);my($Hwnd)=shift;
my($Ret)=$GetForegroundHwnd->Call($Hwnd,$Ptr1);
$obj->{Error}=unpack("l",$Ptr1);
if($Ret){return $Ret}
else{return undef;}}

sub HideProcess
{if(Win32::IsWinNT){croak "\nHideProcess() is not yet supported under WinNT\n";}
my($obj)=shift;
if(scalar(@_)!=1){croak "\n[Error] Parameters do not correspond in HideProcess()\n";}
my($Ptr1)=pack("l",0);
my($Ret)=$HideProcess->Call($_[0],1,$Ptr1);
$obj->{Error}=unpack("l",$Ptr1);
if($Ret){return $Ret;}
else{return undef;}}

sub ShowProcess
{if(Win32::IsWinNT){croak "\nShowProcess() is not yet supported under WinNT\n";}
my($obj)=shift;
if(scalar(@_)!=1){croak "\n[Error] Parameters do not correspond in ShowProcess()\n";}
my($Ptr1)=pack("l",0);my($Ptr2)=pack("L",0);
my($Ret)=$HideProcess->Call($_[0],0,$Ptr1);
$obj->{Error}=unpack("l",$Ptr1);
if($Ret){return $Ret;}
else{return undef;}}

sub KeyCtrlOff
{if(Win32::IsWinNT) {croak "\nKeyCtrlOff() is not yet supported under WinNT\n";}
my($obj)=shift;
if(scalar(@_)!=0){croak "\n[Error] Parameters do not correspond in KeyCtrlOff()\n";}
my($Ptr1)=pack("l",0);
my($Ret)=$KeyCtrl->Call(1,$Ptr1);
$obj->{Error}=unpack("l",$Ptr1);
if ($Ret) {return $Ret;}
else {return undef;}}

sub KeyCtrlOn
{if(Win32::IsWinNT){croak "\nKeyCtrlOn() is not yet supported under WinNT\n";}
my($obj)=shift;
if(scalar(@_)!= 0){croak "\n[Error] Parameters do not correspond in KetCtrlOn()\n";}
my($Ptr1)=pack("l",0);
my($Ret)=$KeyCtrl->Call(0,$Ptr1);
$obj->{Error}=unpack("l",$Ptr1);
if($Ret){return $Ret;}
else{return undef;}}
1;
