#   Modules.pl
#   -----------
#   Dump the list of modules for a given process.
#
#   Copyright (c) 1999 by Dave Roth
#   Courtesty of Roth Consulting
#   http://www.roth.net/
#   Based on code from ModuleList.pl (Example: 7.17)
#   From "Win32 Perl Scripting: Administrators Handbook" by Dave Roth
#   Published by New Riders Publishing.
#   ISBN # 1-57870-215-1
#
#  This script demonstrates the PSAPI by listing all loaded DLL (module) files
#  that each process has.

use Win32::API;
use Getopt::Long;

$VERSION = 20030524;

# Define some contants
$DWORD_SIZE = 4;
$PROC_ARRAY_SIZE = 100;
$MODULE_LIST_SIZE = 200;

# Define some Win32 API constants
$PROCESS_QUERY_INFORMATION = 0x0400;
$PROCESS_VM_READ = 0x0010;
$PROCESS_ALL_ACCESS = 0x1F0FFF;

Configure( \%Config ) || die;
if( $Config{help} )
{
  Syntax();
  exit;
}
if( $Config{kill_process} )
{
  PrepareMorgue();
}

foreach $Param ( @ARGV )
{
  if( $Param =~ /^\d+$/ )
  {
    push( @PidList, $Param );
  }
  else
  {
    push( @ModuleList, $Param );
  }
}

$OpenProcess = new Win32::API( 'kernel32.dll', 'OpenProcess', [N,I,N], N ) || die "Can not link to open proc";
#$OpenProcess = new Win32::API( 'kernel32.dll', 'OpenProcess', [I,I,I,P,P],I) || die "Can not link to open proc";

$CloseHandle = new Win32::API( 'kernel32.dll', 'CloseHandle', [N], I ) || die "Can not link to CloseHandle()";
$EnumProcesses = new Win32::API( 'psapi.dll', 'EnumProcesses', [P,N,P], I ) || die;
$EnumProcessModules = new Win32::API( 'psapi.dll', 'EnumProcessModules', [N,P,N,P], I ) || die "Can not link EnumProcessModules";
$GetModuleBaseName = new Win32::API( 'psapi.dll', 'GetModuleBaseName', [N,N,P,N], N ) || die "Can not link to GetModuleBaseName\n";
$GetModuleFileNameEx = new Win32::API( 'psapi.dll', 'GetModuleFileNameEx', [N,N,P,N], N ) || die "Could not link to GetModuleFileNameEx\n";
$GetProcessMemoryInfo = new Win32::API( 'psapi.dll', 'GetProcessMemoryInfo', [N,P,N], I ) || die "Can not link GetProcessMemoryInfo()\n";

if( 0 == scalar @PidList ) 
{
    @PidList = GetPidList();
}

if( Win32::IsWinNT() )
{
    my $iTotal = 0;

    # Create a buffer
    $ProcArray = MakeBuffer( $DWORD_SIZE * $PROC_ARRAY_SIZE );
    $ProcNum = MakeBuffer( $DWORD_SIZE );

    foreach $Pid ( @PidList )
    {
        my $iModuleCount = 0;
        my $ProcInfo = GetProcessInfo( $Pid, \@ModuleList );

        # If we have been looking for a particular module then
        # go to the next one unless we found one of the modules
        next unless( $ProcInfo->{fModuleFound} );

        print "\n$ProcInfo->{pid} ($ProcInfo->{name})\n";
        if( scalar @{$ProcInfo->{modules}} )
        {
            printf( "  Current memory use: %s\n  Peak memory use: %s\n",
                    FormatNumber( $ProcInfo->{workingset} ),
                    FormatNumber( $ProcInfo->{workingsetpeak} ) );
            if( ! $Config{supress_module_list} )
            {
              print "  Module list:\n"; 
  
              foreach $Module ( @{$ProcInfo->{modules}} )
              {
                  printf( "    % 3d) %s\n", ++$iModuleCount, $Module );
              }
            }
            push( @KillList, { pid => $ProcInfo->{pid}, name => $ProcInfo->{name} } ) if( $Config{kill_process} );
        }
        else
        {
            print "  Unable to get process information.\n";
        }
    }

    if( $Config{kill_process} )
    {
      my $iCount = 0;
      print "\n\nKilling:\n";
      foreach my $Process ( sort { $a->{name} cmp $b->{name} } @KillList )
      {
        printf( "  % 3d) PID: % 5d ( %s )\n", ++$iCount, $Process->{pid}, $Process->{name} );
      }
      if( $Config{no_kill_prompt} )
      {
        KillListOfProcesses( @KillList );
      }
      else
      {
        print "\n    DO YOU WANT TO KILL THESE PROCESSES? 'Yes' or 'No'?\n    >";
        my $Result = <STDIN>;
        chomp( $Result );
        if( "yes" eq lc $Result )
        {
          KillListOfProcesses( @KillList );
        }
        else
        {
          print "\n    ABORTING. These will NOT be killed.\n";
        }
      }
    }
}
else
{
    print "Windows 95/98/ME are not supported.\n";
}

sub GetPidList()
{
    my( @PidList );
    my $ProcArrayLength = $PROC_ARRAY_SIZE;
    my $iIterationCount = 0;
    my $ProcNum;
    my $pProcArray;

    do
    {
        my $ProcArrayByteSize;
        my $pProcNum = MakeBuffer( $DWORD_SIZE );
        # Reset the number of processes since we later use it to test
        # if we worked or not
        $ProcNum = 0;
        $ProcArrayLength = $PROC_ARRAY_SIZE * ++$iIterationCount;
        $ProcArrayByteSize = $ProcArrayLength * $DWORD_SIZE;
        # Create a buffer
        $pProcArray = MakeBuffer( $ProcArrayByteSize );
        if( 0 != $EnumProcesses->Call( $pProcArray, $ProcArrayByteSize, $pProcNum ) )
        {
            # Get the number of bytes used in the array
            # Check this out -- divide by the number of bytes in a DWORD
            # and we have the number of processes returned!
            $ProcNum = unpack( "L", $pProcNum ) / $DWORD_SIZE;
            print "Total procs: $ProcNum\n";
        }
    } while( $ProcNum >= $ProcArrayLength );
    
    if( 0 != $ProcNum )
    {
        # Let's play with each PID
        # First we must unpack each PID from the returned array
        @PidList = unpack( "L$ProcNum", $pProcArray );
    }
    return( @PidList );
}


sub GetProcessInfo()
{
    my( $Pid, $ModuleList ) = @_;
    my( %ProcInfo );

    $ProcInfo{name} = "unknown";
    $ProcInfo{pid}  = $Pid;
    @{$ProcInfo{modules}} = ();

    # We can not open the system Idle process so just hack it.
    $ProcInfo{name} = "Idle" if( 0 == $Pid );

	print "trying to open  $Pid\n";
    my( $hProcess ) = $OpenProcess->Call( $PROCESS_QUERY_INFORMATION | $PROCESS_VM_READ, 0, $Pid );
    if( $hProcess )
    {
       print "opened a process $Pid\n";
		my( $BufferSize ) = $MODULE_LIST_SIZE * $DWORD_SIZE;
        my( $MemStruct ) = MakeBuffer( $BufferSize );
        my( $iReturned ) = MakeBuffer( $BufferSize );

        # If we are looking for particular modules OR if we
        # are not looking for any module in particular then 
        # indicate that we want to display this process
        $ProcInfo{fModuleFound} = ( scalar @{$ModuleList} )? 0:1;
        
        if( $EnumProcessModules->Call( $hProcess, $MemStruct, $BufferSize, $iReturned ) )
        {
            print "enumprocessmoduels $pid\n";
			my( $StringSize ) = 255 * ( ( Win32::API::IsUnicode() )? 2 : 1 );
            my( $ModuleName ) = MakeBuffer( $StringSize );
            my( @ModuleList ) = unpack( "L*", $MemStruct );
            my $hModule = $ModuleList[0];
            my $TotalChars;

            # Like EnumProcesses() divide $Returned by the # of bytes in an HMODULE
            # (which is the same as a DWORD)
            # and that is the number of module handles returned.
            # In this case we only want 1; the first returned in the array is
            # always the module of the process (typically an executable).
            $iReturned = unpack( "L", $iReturned ) / $DWORD_SIZE;

            if( $TotalChars = $GetModuleBaseName->Call( $hProcess, $hModule, $ModuleName, $StringSize ) )
            {
                $ProcInfo{name} = FixString( $ModuleName );
            }
            else
            {
                $ProcInfo{name} = "unknown";
            }

            for( $iIndex = 0; $iIndex < $iReturned; $iIndex++ )
            {
                $hModule = $ModuleList[$iIndex];
                $ModuleName = MakeBuffer( $StringSize );
                if( $GetModuleFileNameEx->Call( $hProcess,
                                            $hModule,
                                            $ModuleName,
                                            $StringSize ) )
                {
                  my $ModuleNameFixed = FixString( $ModuleName );
                    if( 0 == $iIndex )
                    {
                        $ProcInfo{fullname} = $ModuleNameFixed;
                    }
                    push( @{$ProcInfo{modules}}, $ModuleNameFixed );

                    # If we have not determined if we need to display this
                    # process (no specified modules have been found) then
                    # let's look to see if any of the specified modules 
                    # are here
                    if( 0 == $ProcInfo{fModuleFound} )
                    {
                      foreach my $TargetModule ( @{$ModuleList} )
                      {
                        $ProcInfo{fModuleFound} = ( $ModuleNameFixed =~ /$TargetModule/i );
                      }
                    }
                }
            }
        }

        $BufSize = 10 * $DWORD_SIZE;
        $MemStruct = pack( "L10", ( $BufSize, split( "", 0 x 9 ) ) );

        if( $GetProcessMemoryInfo->Call( $hProcess, $MemStruct, $BufSize ) )
        {
          my( @MemStats ) = unpack( "L10", $MemStruct );
          $ProcInfo{workingsetpeak} = $MemStats[2];
          $ProcInfo{workingset} = $MemStats[3];
          $ProcInfo{pagefileuse} = $MemStats[8];
          $ProcInfo{pagefileusepeak} = $MemStats[9];
        }

        $CloseHandle->Call( $hProcess );
    } else {
		  
        print Win32::FormatMessage (Win32::GetLastError ());  
		print "could not open $Pid.. trying to force open\n";
		
		ForceOpen($Pid);

	}
    return( \%ProcInfo );
}

sub MakeBuffer
{
    my( $BufferSize ) = @_;
    return( "\x00"  x $BufferSize );
}

sub FixString
{
    my( $String ) = @_;
    $String =~ s/(.)\x00/$1/g if( Win32::API::IsUnicode() );
    return( unpack( "A*", $String ) );
}

sub FormatNumber
{
    my( $Number ) = @_;
    while ($Number =~ s/^(-?\d+)(\d{3})/$1,$2/){};
    return( $Number );
}

sub KillListOfProcesses 
{
  my( @KillList ) = @_;
  print "\n    Killing...\n";
  $iCount = 0;
  foreach my $Process ( sort { $a->{name} cmp $b->{name} } @KillList )
  {
    printf( "    % 3d) PID: % 5d ( %s ) ... ", ++$iCount, $Process->{pid}, $Process->{name} );
    if( Kill( $Process->{pid} ) )
    {
      print "killed.";
    }
    else
    {
      print "FAILED TO KILL.";
    }
    print "\n";
  }
}

sub Kill 
{
  my( $Pid ) = @_;
  my $fResult = 0;

  if( !( $fResult = kill( $Pid, 0 ) ) )
  {
    $fResult = ForceKill( $Pid );
  }
  return( $fResult );
}

sub ForceKill
{


    my( $Pid ) = @_;
    my $iResult = 0;
    my $phToken = pack( "L", 0 );
    if( $OpenProcessToken->Call( $GetCurrentProcess->Call(), $TOKEN_ADJUST_PRIVILEGES | $TOKEN_QUERY, $phToken ) )
    {
        my $hToken = unpack( "L", $phToken );
        if( SetPrivilege( $hToken, $SE_DEBUG_NAME, 1 ) )
        {
            my $hProcess = $OpenProcess->Call( $PROCESS_TERMINATE, 0, $Pid );
            if( $hProcess )
            {
                SetPrivilege( $hToken, $SE_DEBUG_NAME, 0 );
                $iResult = $TerminateProcess->Call( $hProcess, 0 );
                $CloseHandle->Call( $hProcess );    
            }
        }
        $CloseHandle->Call( $hToken );
    }
    return( $iResult );
}     


sub ForceOpen
{
    
	$TOKEN_QUERY                = 0x0008;
    $TOKEN_ADJUST_PRIVILEGES    = 0x0020;
    $SE_PRIVILEGE_ENABLED       = 0x02;
    $PROCESS_TERMINATE          = 0x0001;
    $SE_DEBUG_NAME              = "SeDebugPrivilege";

    $GetCurrentProcess = new Win32::API( 'Kernel32.dll', 'GetCurrentProcess', [], N ) || die;
    $OpenProcessToken = new Win32::API( 'AdvApi32.dll', 'OpenProcessToken', [N,N,P], I ) || die;
    $LookupPrivilegeValue = new Win32::API( 'AdvApi32.dll', 'LookupPrivilegeValue', [P,P,P], I ) || die;
    $AdjustTokenPrivileges = new Win32::API( 'AdvApi32.dll', 'AdjustTokenPrivileges', [N,I,P,N,P,P], I ) || die;
    $TerminateProcess = new Win32::API( 'Kernel32.dll', 'TerminateProcess', [N,I], I ) || die;

	
	my( $Pid ) = @_;
    my $iResult = 0;
    my $phToken = pack( "L", 0 );
    if( $OpenProcessToken->Call( $GetCurrentProcess->Call(), $TOKEN_ADJUST_PRIVILEGES | $TOKEN_QUERY, $phToken ) )
    {
        my $hToken = unpack( "L", $phToken );
        if( SetPrivilege( $hToken, $SE_DEBUG_NAME, 1 ) )
        {
            my $hProcess = $OpenProcess->Call( $PROCESS_ALL_ACCESS  , 0, $Pid );
            if( $hProcess )
            {
                SetPrivilege( $hToken, $SE_DEBUG_NAME, 0 );
                print "forced open pid $Pid\n";

				      
		my( $BufferSize ) = $MODULE_LIST_SIZE * $DWORD_SIZE;
        my( $MemStruct ) = MakeBuffer( $BufferSize );
        my( $iReturned ) = MakeBuffer( $BufferSize );

        # If we are looking for particular modules OR if we
        # are not looking for any module in particular then 
        # indicate that we want to display this process
        $ProcInfo{fModuleFound} = ( scalar @{$ModuleList} )? 0:1;
        
        if( $EnumProcessModules->Call( $hProcess, $MemStruct, $BufferSize, $iReturned ) )
        {
            print "enumprocessmoduels $pid\n";
			my( $StringSize ) = 255 * ( ( Win32::API::IsUnicode() )? 2 : 1 );
            my( $ModuleName ) = MakeBuffer( $StringSize );
            my( @ModuleList ) = unpack( "L*", $MemStruct );
            my $hModule = $ModuleList[0];
            my $TotalChars;

            # Like EnumProcesses() divide $Returned by the # of bytes in an HMODULE
            # (which is the same as a DWORD)
            # and that is the number of module handles returned.
            # In this case we only want 1; the first returned in the array is
            # always the module of the process (typically an executable).
            $iReturned = unpack( "L", $iReturned ) / $DWORD_SIZE;

            if( $TotalChars = $GetModuleBaseName->Call( $hProcess, $hModule, $ModuleName, $StringSize ) )
            {
                $ProcInfo{name} = FixString( $ModuleName );
            }
            else
            {
                $ProcInfo{name} = "unknown";
            }

            for( $iIndex = 0; $iIndex < $iReturned; $iIndex++ )
            {
                $hModule = $ModuleList[$iIndex];
                $ModuleName = MakeBuffer( $StringSize );
                if( $GetModuleFileNameEx->Call( $hProcess,
                                            $hModule,
                                            $ModuleName,
                                            $StringSize ) )
                {
                  my $ModuleNameFixed = FixString( $ModuleName );
                    if( 0 == $iIndex )
                    {
                        $ProcInfo{fullname} = $ModuleNameFixed;
                    }
                    push( @{$ProcInfo{modules}}, $ModuleNameFixed );

                    # If we have not determined if we need to display this
                    # process (no specified modules have been found) then
                    # let's look to see if any of the specified modules 
                    # are here
                    if( 0 == $ProcInfo{fModuleFound} )
                    {
                      foreach my $TargetModule ( @{$ModuleList} )
                      {
                        $ProcInfo{fModuleFound} = ( $ModuleNameFixed =~ /$TargetModule/i );
                      }
                    }
                }
            }
        } else {

			   
			  print "could not force $Pid.. ". Win32::FormatMessage (Win32::GetLastError ());  ;
		}


        $BufSize = 10 * $DWORD_SIZE;
        $MemStruct = pack( "L10", ( $BufSize, split( "", 0 x 9 ) ) );

        if( $GetProcessMemoryInfo->Call( $hProcess, $MemStruct, $BufSize ) )
        {
          my( @MemStats ) = unpack( "L10", $MemStruct );
          $ProcInfo{workingsetpeak} = $MemStats[2];
          $ProcInfo{workingset} = $MemStats[3];
          $ProcInfo{pagefileuse} = $MemStats[8];
          $ProcInfo{pagefileusepeak} = $MemStats[9];
		  print "workingset = $MemStats[3]\n";
        }



                $CloseHandle->Call( $hProcess );    
            }
        }
        $CloseHandle->Call( $hToken );
    }
    return( $iResult );
}   

sub SetPrivilege
{
    my( $hToken, $pszPriv, $bSetFlag ) = @_;
    my $pLuid = pack( "Ll", 0, 0 );
    if( $LookupPrivilegeValue->Call( "\x00\x00", $pszPriv, $pLuid ) )
    {
        my $pPrivStruct = pack( "LLlL", 1, unpack( "Ll", $pLuid ), ( ( $bSetFlag )? $SE_PRIVILEGE_ENABLED : 0 ) );
        $iResult = ( 0 != $AdjustTokenPrivileges->Call( $hToken, 0,$pPrivStruct, length( $pPrivStruct ), 0, 0 ) );
    }
	return( $iResult );
}

sub PrepareMorgue
{
    $TOKEN_QUERY                = 0x0008;
    $TOKEN_ADJUST_PRIVILEGES    = 0x0020;
    $SE_PRIVILEGE_ENABLED       = 0x02;
    $PROCESS_TERMINATE          = 0x0001;
    $SE_DEBUG_NAME              = "SeDebugPrivilege";

    $GetCurrentProcess = new Win32::API( 'Kernel32.dll', 'GetCurrentProcess', [], N ) || die;
    $OpenProcessToken = new Win32::API( 'AdvApi32.dll', 'OpenProcessToken', [N,N,P], I ) || die;
    $LookupPrivilegeValue = new Win32::API( 'AdvApi32.dll', 'LookupPrivilegeValue', [P,P,P], I ) || die;
    $AdjustTokenPrivileges = new Win32::API( 'AdvApi32.dll', 'AdjustTokenPrivileges', [N,I,P,N,P,P], I ) || die;
    $TerminateProcess = new Win32::API( 'Kernel32.dll', 'TerminateProcess', [N,I], I ) || die;
}

sub Configure
{
  my( $Config ) = @_;
  my $Result;
  Getopt::Long::Configure( "prefix_pattern=(-|\/)" );
  $Result = GetOptions( $Config, qw(
                        supress_module_list|s
                        kill_process|k
                        no_kill_prompt|no_prompt
                        help|?
                        ) );
  return( $Result );
}

sub Syntax 
{
  my $Path = Win32::GetLongPathName( join( "", Win32::GetFullPathName( $0 ) ) );
  my( $Script ) = ( $Path =~ /([^\\]+)$/ );
  print<<"EOT";
$Script

This will display processes and their loaded modules.
Version: $VERSION
                                        
  Syntax:
  $Script [/s][/k [/no_prompt]][/?] <NAME | PID> [<NAME2 | PID2 [...]]
    s...........Supress printing the (possibly lengthy) list of modules
                per process.
    k...........Kill every process that is listed.
    no_prompt...Do not prompt for killing processes.                      
    NAME........The name of a module. This must be the full name such as 
                "wininet.dll" or "shell"
    PID.........A process ID.                    
              
    Example:
      $Script 1234
      $Script wininet.dll
      $Script 1234 332 wininet.dll /s
      $Script wininet.dll /s /k /no_prompt
EOT
}

__END__

History:
  20010119 roth
    - Created.(?)

  20030523 roth
    - Added ability to supress the lengthy module list (/s)
    - Added configuration routine and syntax.

  20030524 roth
    - Added ability to kill resulting list of processes.
    - Added the /no_prompt flag to prevent the prompt if you want to kill processes.
