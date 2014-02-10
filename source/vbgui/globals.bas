Attribute VB_Name = "globals"
'Option Explicit
Public DB_CONNECTION_STRING As String 'holds conection string used by the vaDataAccess class
Public Const APPKEY = "Software\Recursive Technology\VadminUISnapin"

Public Enum enDays
    SchMonday = 1
    SchTuesday = 2
    SchWedensday = 4
    SchThursday = 8
    SchFriday = 16
    SchSaturday = 32
    SchSunday = 64
    SchEvery = 128
End Enum

Public Sub setconstring(Dsn As String, uid As String, pwd As String)

DB_CONNECTION_STRING = "DSN=" & Dsn & ";UID=" & uid & ";PWD=" & pwd
'Debug.Print "WSANO_DATA = " & WSANO_DATA

End Sub


Sub memorybycomponent(ByVal ResultView As SnapInLib.ResultView, sv_name)

Dim rptrs As New ADODB.Recordset
Dim dobj As New VadminUI.vaDataAccess
Dim i As Long

Dim sqlstr As String
  sqlstr = "select sum(virtualmem)""virtualmem"", sum(memory) ""physical memory""" _
  & ",monitored_comps.cc_name ""cc_name"" from processes, monitored_comps where monitored_comps.cc_alias = processes.cc_alias or" _
& " monitored_comps.cc_name = processes.cc_name and processes.sv_name = '" & sv_name & "' group by  monitored_comps.cc_name"


Set rptrs = dobj.returndataset(sqlstr)


With ResultView.Control

    .Subsets = 2
    .AltFreqThreshold = 100
    .FontSizeGlobalCntl = 0.6
    
'On Error GoTo Finish

.Points = rptrs.RecordCount

If Not (rptrs Is Nothing) Then
                If Not (rptrs.BOF And rptrs.EOF) Then
                    rptrs.MoveFirst
                    i = 0
                    Do While Not rptrs.EOF
                           
                           
                                mem = rptrs("physical memory").value
                                virtualmem = rptrs("virtualmem").value
                                
                                Debug.Print "mem = " & mem
                                Debug.Print "virtualmem - " & virtualmem
                                
                                If IsNull(mem) Then
                                    mem = 0
                                End If
                                
                                If IsNull(virtualmem) Then
                                    virtualmem = 0
                                End If
         
                                .YData(0, i) = mem
                                .YData(1, i) = virtualmem
                                
                                ccName = Trim(rptrs("cc_name").value)
                                
                                'Debug.Print "ccname = " & ccName
                                
                               .PointLabels(i) = ccName
                               '"testxxxxxxxxxxxxxxxxxxxxx"
                            
                         i = i + 1
                        rptrs.MoveNext
                    
                    Loop
                 End If
End If

    .DeskColor = RGB(192, 192, 192)
    .GraphBackColor = 0
    .GraphForeColor = RGB(255, 255, 255)
    
    
    
    '** Set SubsetLabels property array for 4 subsets **'
    .SubsetLabels(0) = "Physical Memory"
    .SubsetLabels(1) = "Virtual Memory"
    
        '** Set DataShadows to show 3D
    .DataShadows = PEDS_3D
    
    .MainTitle = sv_name & " Component Resource Consumption"
    .SubTitle = ""
    .YAxisLabel = "KBs of Memory"
    .XAxisLabel = "Component Name"
    .FocalRect = False
    .PlottingMethod = GPM_BAR
    .GridLineControl = PEGLC_NONE
    .AllowRibbon = True
    
    .SubsetColors(0) = QBColor(12) ' or use RGB Function
    .SubsetColors(1) = QBColor(11)
 
   '** this is how to change line types **'
    .SubsetLineTypes(0) = PELT_THINSOLID
    .SubsetLineTypes(1) = PELT_DASH
    
        '** this is how to change point types **'
    .SubsetPointTypes(0) = PEPT_DOTSOLID
    .SubsetPointTypes(1) = PEPT_UPTRIANGLESOLID
    
    .MarkDataPoints = True

    
        '** Always call PEactions = 0 at end **'
    .PEactions = 0


End With

Finish:


End Sub


Sub memorybyprocess(ByVal ResultView As SnapInLib.ResultView, sft_elmnt_id)


Dim rptrs As New ADODB.Recordset
Dim dobj As New VadminUI.vaDataAccess

Set rptrs = dobj.returndataset("select * from processes where sft_elmnt_id = " & sft_elmnt_id)
'"select * from stat_vals where collector_id = " & pid)


With ResultView.Control

    .AltFreqThreshold = 100
    .FontSizeGlobalCntl = 0.6
    .Subsets = 2
    .Points = rptrs.RecordCount

If Not (rptrs Is Nothing) Then
                If Not (rptrs.BOF And rptrs.EOF) Then
                    rptrs.MoveFirst
                    i = 0
                    Do While Not rptrs.EOF
                           
                                mem = rptrs("memory").value
                                virtualmem = rptrs("virtualmem").value
                                
                                If IsNull(mem) Then
                                    mem = 0
                                End If
                                
                                If IsNull(virtualmem) Then
                                    virtualmem = 0
                                End If
                                
                                .YData(0, i) = mem
                                .YData(1, i) = virtualmem
                                
                                Dim labelstring As String
                                Dim pname As String
                                
                                Dim cc_alias As String
                                Dim cc_name As String
                                Dim process As String
                                
                                
                                cc_alias = Trim(IIf(IsNull(rptrs("cc_alias").value), " ", rptrs("cc_alias").value))
                                cc_name = Trim(IIf(IsNull(rptrs("cc_name").value), " ", rptrs("cc_name").value))
                                process = Trim(IIf(IsNull(rptrs("process").value), " ", rptrs("process").value))
                                
                                                                
                                Debug.Print "cc_alias = " & cc_alias & " cc_name = " & cc_name & " process = " & process

                                If (cc_name <> "") Then
                                    pname = cc_name
                                ElseIf (cc_alias <> "") Then
                                    pname = cc_alias
                                Else
                                    pname = process
                                End If
                                
                                
                                labelstring = rptrs("pid").value & " " & pname
                                
                                
                                .PointLabels(i) = labelstring
                         
                            i = i + 1
                        rptrs.MoveNext
                    
                    Loop
                 End If
End If

    .DeskColor = RGB(192, 192, 192)
    .GraphBackColor = 0
    .GraphForeColor = RGB(255, 255, 255)
    
    
    
    '** Set SubsetLabels property array for 4 subsets **'
    .SubsetLabels(0) = "Memory"
    .SubsetLabels(1) = "Virtual Memory"
    
        '** Set DataShadows to show 3D
    .DataShadows = PEDS_3D
    
    .MainTitle = "Resource Consumption by Process"
    .SubTitle = ""
    .YAxisLabel = "KBs of Memory"
    .XAxisLabel = "Process ID"
    .FocalRect = False
    .PlottingMethod = GPM_BAR
    .GridLineControl = PEGLC_NONE
    .AllowRibbon = True
    
    .SubsetColors(0) = QBColor(12) ' or use RGB Function
    .SubsetColors(1) = QBColor(11)
 
   '** this is how to change line types **'
    .SubsetLineTypes(0) = PELT_THINSOLID
    .SubsetLineTypes(1) = PELT_DASH
    
        '** this is how to change point types **'
    .SubsetPointTypes(0) = PEPT_DOTSOLID
    .SubsetPointTypes(1) = PEPT_UPTRIANGLESOLID
    
        '** Always call PEactions = 0 at end **'
    .PEactions = 0

End With

End Sub

Sub cpubyprocess(ByVal ResultView As SnapInLib.ResultView, sft_elmnt_id)

Dim rptrs As New ADODB.Recordset
Dim dobj As New VadminUI.vaDataAccess

Set rptrs = dobj.returndataset("select * from processes where sft_elmnt_id = " & sft_elmnt_id)
'"select * from stat_vals where collector_id = " & pid)


With ResultView.Control

    .AltFreqThreshold = 100
    .FontSizeGlobalCntl = 0.6
    .Subsets = 3
    .Points = rptrs.RecordCount

If Not (rptrs Is Nothing) Then
                If Not (rptrs.BOF And rptrs.EOF) Then
                    rptrs.MoveFirst
                    i = 0
                    Do While Not rptrs.EOF
                           
                                cpu_time = rptrs("cpu_time").value
                                kernel_time = rptrs("kernel_time").value
                                user_time = rptrs("user_time").value
               
                                If IsNull(cpu_time) Then
                                    cpu_time = 0
                                End If
                        
                                If IsNull(kernel_time) Then
                                    kernel_time = 0
                                End If
                                
                                If IsNull(user_time) Then
                                    user_time = 0
                                End If
                                
                                
                                
                                .YData(0, i) = user_time
                                .YData(1, i) = kernel_time
                                .YData(2, i) = cpu_time

                                Dim labelstring As String
                                Dim pname As String
                                
                                Dim cc_alias As String
                                Dim cc_name As String
                                Dim process As String
                                
                                cc_alias = Trim(IIf(IsNull(rptrs("cc_alias").value), " ", rptrs("cc_alias").value))
                                cc_name = Trim(IIf(IsNull(rptrs("cc_name").value), " ", rptrs("cc_name").value))
                                process = Trim(IIf(IsNull(rptrs("process").value), " ", rptrs("process").value))
                                
                                
                                Debug.Print "cc_alias = " & cc_alias & " cc_name = " & cc_name & " process = " & process
                                
                                
                                If (cc_name <> "") Then
                                    pname = cc_name
                                ElseIf (cc_alias <> "") Then
                                    pname = cc_alias
                                Else
                                    pname = process
                                End If
                                
                                  
                                labelstring = rptrs("pid").value & " " & pname
                                
                                
                                .PointLabels(i) = labelstring
                            
                         i = i + 1
                        rptrs.MoveNext
                    
                    Loop
                 End If
End If

    .DeskColor = RGB(192, 192, 192)
    .GraphBackColor = 0
    .GraphForeColor = RGB(255, 255, 255)
    
    
    
    '** Set SubsetLabels property array for 4 subsets **'
    .SubsetLabels(0) = "User Time"
    .SubsetLabels(1) = "Kernel Time"
    .SubsetLabels(2) = "Total CPU Time"
    
        '** Set DataShadows to show 3D
    .DataShadows = PEDS_3D
    
    .MainTitle = "CPU use by Process"
    .SubTitle = ""
    .YAxisLabel = "Time in Seconds"
    .XAxisLabel = "Process ID"
    .FocalRect = False
    .PlottingMethod = GPM_BAR
    .GridLineControl = PEGLC_NONE
    .AllowRibbon = True
    
    .SubsetColors(0) = QBColor(12) ' or use RGB Function
    .SubsetColors(1) = QBColor(11)
    .SubsetColors(2) = QBColor(13)
 
   '** this is how to change line types **'
    .SubsetLineTypes(0) = PELT_THINSOLID
    .SubsetLineTypes(1) = PELT_DASH
    
        '** this is how to change point types **'
    .SubsetPointTypes(0) = PEPT_DOTSOLID
    .SubsetPointTypes(1) = PEPT_UPTRIANGLESOLID
    
        '** Always call PEactions = 0 at end **'
    .PEactions = 0

End With



End Sub



Sub processmempie(ByVal ResultView As SnapInLib.ResultView, sv_name, pid)

Dim rptrs As New ADODB.Recordset
Dim dobj As New VadminUI.vaDataAccess

Dim recset As ADODB.Recordset
Dim HostName As String
Dim oLoc As SWbemLocator
Dim oServices As SWbemServices
Set oLoc = New SWbemLocator


Set recset = dobj.returndataset("select t1.hostname, t1.username,t1.password from host t1, sft_elmnt t2 where t2.host = " _
  & "t1.hostname and t2.sft_elmnt_id = " & pid)

HostName = Trim(recset("hostname").value & "")
password = Trim(recset("password").value & "")
username = Trim(recset("username").value & "")

' On Error GoTo endsub

Set oServices = oLoc.ConnectServer(HostName, strUser:=username, _
strPassword:=password)

Dim oObjSet As SWbemObjectSet
Set oObjSet = oServices.InstancesOf("Win32_OperatingSystem")

For Each service In oObjSet
    os_totalmem = service.TotalVisibleMemorySize
Next

 Debug.Print "os_totalmem = " & os_totalmem

Set rptrs = dobj.returndataset("select * from processes where sft_elmnt_id = " & pid)

   

With ResultView.Control
        
        '** Set how much data object will hold **'
        .FontSizeGlobalCntl = 0.6
        .Subsets = 1
        .Points = rptrs.RecordCount + 1
        
        '** Pass data for slices **'
     Dim colornum As Integer
     colornum = 3
     Dim relativemem
     
     If Not (rptrs Is Nothing) Then
                    If Not (rptrs.BOF And rptrs.EOF) Then
                        rptrs.MoveFirst
                        i = 0
                        
                        Do While Not rptrs.EOF
                               
                                    mem = rptrs("memory").value
                                    virtualmem = rptrs("virtualmem").value
                                    
                                    If IsNull(mem) Then
                                        mem = 0
                                    End If
                                    
                                    If IsNull(vitualmem) Then
                                       virtualmem = 0
                                    End If
    
                                    Debug.Print "mem = " & mem
                                    mem = mem + 0
                                    .XData(0, i) = mem & ""
                                    'mem
                                    
                                    .PointLabels(i) = rptrs("pid").value & " : " & Trim(rptrs("process").value)
                                    .SubsetColors(i) = QBColor(colornum)
                                    
                                    relativemem = relativemem + mem
                                    
                                    .YData(0, i) = 1 ' New Mexico
                                    
                                    Debug.Print "relative mem = " & relativemem
                                    
                                    If colornum = 15 Then
                                         colornum = 3
                                    Else
                                        colornum = colornum + 1
                                    End If
                                
                             i = i + 1
                            rptrs.MoveNext
                        
                        Loop
                     End If
    End If
     
     Debug.Print "final relative mem = " & relativemem
    Dim othermem As Long
    othermem = os_totalmem - relativemem
    Debug.Print "othermem = " & othermem
    
    .XData(0, i) = othermem
    .PointLabels(i) = "Other Pysical Memory"
    .SubsetColors(i) = QBColor(2)
    .GroupingPercent = 3
    
    
        '** Set Titles **'
        .MainTitle = sv_name & " Memory Useage by Process"
        .SubTitle = "Host = " & HostName
        
        '** Set various other properties **'
        .FocalRect = False
        .DataPrecision = 1
    
        .GroupingPercent = 0
        .DeskColor = RGB(192, 192, 192)
        .DataShadows = PEDS_3D
       ' .AutoExplode = PEAE_ALLSUBSETS
    
        .PEactions = 0
    End With
Exit Sub

endsub:

    ResultView.Control.MainTitle = "ERROR: WMI DATA RETREVAL ERROR"
    ResultView.Control.SubTitle = Err.description

End Sub

Sub componentpie(ByVal ResultView As SnapInLib.ResultView, sv_name, pid)

Dim rptrs As New ADODB.Recordset
Dim dobj As New VadminUI.vaDataAccess

Dim recset As ADODB.Recordset
Dim HostName As String
Dim oLoc As SWbemLocator
Dim oServices As SWbemServices
Set oLoc = New SWbemLocator


Set recset = dobj.returndataset("select t1.hostname, t1.username,t1.password from host t1, sft_elmnt t2 where t2.host = " _
  & "t1.hostname and t2.sft_elmnt_id = " & pid)

HostName = Trim(recset("hostname").value & "")
password = Trim(recset("password").value & "")
username = Trim(recset("username").value & "")


Dim sqlstr As String
  sqlstr = "select sum(memory) ""memory""" _
  & ",monitored_comps.cc_name ""cc_name"" from processes, monitored_comps where monitored_comps.cc_alias = processes.cc_alias or" _
& " monitored_comps.cc_name = processes.cc_name and processes.sv_name = '" & sv_name & "' group by  monitored_comps.cc_name"


Set rptrs = dobj.returndataset(sqlstr)


    
'On Error GoTo wmierror
    
Set oServices = oLoc.ConnectServer(HostName, strUser:=username, _
strPassword:=password)

Dim oObjSet As SWbemObjectSet
Set oObjSet = oServices.InstancesOf("Win32_OperatingSystem")

For Each service In oObjSet
    os_totalmem = service.TotalVisibleMemorySize
Next

 Debug.Print "os_totalmem = " & os_totalmem


With ResultView.Control
        

        .FontSizeGlobalCntl = 0.6
        '** Set how much data object will hold **'
        .Subsets = 1
        .Points = rptrs.RecordCount + 1
        
        '** Pass data for slices **'
     Dim colornum As Integer
     colornum = 3
     Dim relativemem
     
     If Not (rptrs Is Nothing) Then
                    If Not (rptrs.BOF And rptrs.EOF) Then
                        rptrs.MoveFirst
                        i = 0
                        
                        Do While Not rptrs.EOF
                               
                                    mem = rptrs("memory").value
                                   
    
                                    Debug.Print "mem = " & mem
                                    If IsNull(mem) Then
                                        mem = 0
                                    End If
                                    
                                    .XData(0, i) = mem
                                    'mem
                                    
                                    .PointLabels(i) = Trim(rptrs("cc_name").value)
                                    .SubsetColors(i) = QBColor(colornum)
                                    
                                    relativemem = relativemem + mem
                                    
                                    .YData(0, i) = 1 ' New Mexico
                                    
                                    Debug.Print "relative mem = " & relativemem
                                    
                                    If colornum = 15 Then
                                         colornum = 3
                                    Else
                                        colornum = colornum + 1
                                    End If
                                
                             i = i + 1
                            rptrs.MoveNext
                        
                        Loop
                     End If
    End If
     
     Debug.Print "final relative mem = " & relativemem
    Dim othermem As Long
    othermem = os_totalmem - relativemem
    Debug.Print "othermem = " & othermem
    
    .XData(0, i) = othermem
    .PointLabels(i) = "Other Pysical Memory"
    .SubsetColors(i) = QBColor(2)
    
    
    
        '** Set Titles **'
        .MainTitle = sv_name & " Appserver Memory Useage by Component"
        .SubTitle = "Host = " & HostName
        
        '** Set various other properties **'
        .FocalRect = False
        .DataPrecision = 1
    
        .GroupingPercent = 0
        .DeskColor = RGB(192, 192, 192)
        .DataShadows = PEDS_3D
       ' .AutoExplode = PEAE_ALLSUBSETS
    
        .PEactions = 0
End With

Exit Sub

wmierror:

    ResultView.Control.MainTitle = "ERROR: WMI DATA RETREVAL ERROR"
    ResultView.Control.SubTitle = Err.description
        

End Sub

Sub sendlogchange(sft_elmnt_id As Integer)

Dim IPAddr As Long
Dim rc As Long
Dim Host As String
Dim stat As String
Dim StartupData As WSADataType
Dim SocketNum As Long
Dim ReadSock As Long
Dim SocketBuffer As sockaddr
Dim ReadSockBuffer As sockaddr
Dim ReadBuffer As String * 2048
Dim dobj As New VadminUI.vaDataAccess
Dim program 'program will be the string we send to the ccserver
Dim sqlstr As String
Dim rptrs As ADODB.Recordset
Dim ccport
Dim cchost
Dim vlsmport
Dim vlsmhost
Dim connect_tcp As Boolean



Dim x As Single
Dim Y As Single
Dim bytes As Long


rc = WSACleanup()

rc = WSAStartup(&H101, StartupData)
If rc = SOCKET_ERROR Then
    Debug.Print "SOCKET_ERROR"
    'ConsoleMsgBox "SOCKET_ERROR"
 Exit Sub
End If
    
    
program = "CCOK" 'default
    

sqlstr = "select t1.host, t1.port from sft_elmnt t1 where t1.type = 'v2centralserver'"
Set rptrs = dobj.returndataset(sqlstr)

If Not (rptrs Is Nothing) Then
                If Not (rptrs.BOF And rptrs.EOF) Then
                    rptrs.MoveFirst
                    ccport = Trim(rptrs("port").value)
                    cchost = Trim(rptrs("host").value)
                    'password = Trim(rptrs("password").value)
                    
                End If
End If
    
Debug.Print "ccHost = " & cchost
Debug.Print "ccPort = " & ccport


'if sft_elmnt_id is passed in we are checking on a software element
If sft_elmnt_id > 0 Then
        sqlstr = "select t1.host, t1.port from sft_elmnt t1, sft_elmnt t2 where t2.host = " _
      & "t1.host and t1.type = 'vlsm' and t2.sft_elmnt_id = " & sft_elmnt_id
    
    
    Set rptrs = dobj.returndataset(sqlstr)
    
    If Not (rptrs Is Nothing) Then
                    If Not (rptrs.BOF And rptrs.EOF) Then
                        rptrs.MoveFirst
                        vlsmport = Trim(rptrs("port").value & "")
                        vlsmhost = Trim(rptrs("host").value & "")
                        'password = Trim(rptrs("password").value)
                        
                    End If
    End If
    
    'do not check elements that do not resolve a host correctly
    If (vlsmhost = "") Then
        connect_tcp = True
        Exit Sub
    End If
        
    program = "RESTART APPLOG WATCHER:" & vlsmhost & ":" & vlsmport & ":EOM"
End If


Debug.Print "message to CC = " & program

    IPAddr = GetHostByNameAlias(cchost)
    If IPAddr = -1 Then
        stat = "Cannot locate host " + cchost
        Debug.Print stat
        Exit Sub
    End If
    SocketNum = socket(AF_INET, SOCK_STREAM, 0)
    If SocketNum = SOCKET_ERROR Then
        stat = "Cannot Create Socket."
        Debug.Print stat
        Exit Sub
    End If
    SocketBuffer.sin_family = AF_INET
    SocketBuffer.sin_port = htons(ccport)
    SocketBuffer.sin_addr = IPAddr
    SocketBuffer.sin_zero = String$(8, 0)
    rc = connect(SocketNum, SocketBuffer, Len(SocketBuffer))
    If rc = SOCKET_ERROR Then
        closesocket SocketNum
        stat = "Connect rejected"
        Debug.Print stat
        MsgBox "WARNING! THE CENTRAL SERVER CAN NOT BE CONTACTED.  MAKE SURE THE CENTRAL SERVICE IS RUNNING ON" _
        & vbCrLf & "THE HOST: " & cchost & " PORT: " & ccport, 48
        connect_tcp = False
        Exit Sub
    End If
    
    rc = SendData(SocketNum, program & vbCrLf)
    
     bytes = recv(SocketNum, ReadBuffer, 2048, 0)
    If bytes > 0 Then
        program = Left$(ReadBuffer, bytes)
        stat = "Data Read"
        Debug.Print stat
        Debug.Print program
        If InStr(program, "VLSMISOK") > 0 Then
            Debug.Print "EVERY THING IS OK!!!"
            connect_tcp = True
        End If
    ElseIf WSAGetLastError() <> WSAEWOULDBLOCK Then
        x = WSAAsyncSelect(SocketNum, 0, ByVal &H202, ByVal FD_CONNECT Or FD_ACCEPT)
        stat = "Socket Closed"
        If InStr(program, Chr$(13)) <> 0 Then
            program = Left$(program, InStr(program, Chr$(13)) - 1)
        End If
        Debug.Print "would block..."
        Debug.Print stat
        
        MsgBox "WARNING! The LSM That supports this Software Element could not be confirmed to be running." _
        & vbCrLf & " Make sure the LSM Service is running on the HOST: " & vlsmhost & " PORT: " & vlsmport, 48
     
        'closesocket (ReadSock)
        connect_tcp = False
    End If

Set dobj = Nothing


End Sub

'Error Handler
Public Function ErrorH(ByVal Context As Integer) As Integer
'Context - sub ID
    Screen.MousePointer = vbDefault
    MsgBox "Error " & str$(Err.number) & vbCrLf & Err.description & IIf(Context = 0, "", vbCrLf & "Context: " & str$(Context)), vbCritical
End Function

Public Sub SetFocusCtrl(ByRef ctrl As VB.Control) ' VB.TextBox)
    On Error Resume Next
    If ctrl.Enabled Then ctrl.SetFocus
End Sub

Public Sub SelTextbox(ByRef TB As VB.TextBox)
    With TB
        .SelStart = 0
        .SelLength = Len(.Text)
    End With
End Sub

'Convert string to Long
Public Function StringToLong(ByVal NumberString As String) As Long
    On Error GoTo err_Handler
    
    Dim i As Long
    Dim stTmp As String
    Dim stResult As String
    Dim IsContinue As Boolean  'Is not first allowable time

    For i = 1 To Len(NumberString)
        stTmp = Mid$(NumberString, i, 1)
        Select Case stTmp
        Case "-"
            If Not IsContinue Then  'Only first time
                stResult = stResult & stTmp
                IsContinue = True
            End If
        Case "0" To "9"
            IsContinue = True
            stResult = stResult & stTmp
        End Select
    Next i

    If Len(stResult) = 0 Then
        StringToLong = 0&
        Exit Function
    End If
    If CDbl(stResult) > 2147483647 Then
        stResult = Left$(stResult, 9)
    End If
    StringToLong = CLng(stResult)

    Exit Function
err_Handler:
    StringToLong = 0
    Exit Function
End Function

Public Function LoadRsToCmb(ByRef rs As ADODB.Recordset, ByRef cmb As VB.ComboBox) As Long
On Error GoTo ErroroHandler

    With cmb
        .Clear
        Do Until rs.EOF
            If rs.Fields.Count = 1 Then
                .AddItem Trim(rs.Fields(0).value & "")
            Else
                .AddItem Trim(rs.Fields(1).value & "")
                .ItemData(.NewIndex) = rs.Fields(0).value
            End If
            rs.MoveNext
        Loop
        If .ListCount > 0 Then
            .ListIndex = 0
        End If
        LoadRsToCmb = .ListCount
    End With
 
    Exit Function
ErroroHandler:
    ErrorH 0
    Exit Function
End Function

Public Function ComboListIndexByItemDate(cmb As ComboBox, ItemData As Variant) As Long
    Dim i As Long
    With cmb
        For i = 0 To .ListCount - 1
            If .ItemData(i) = ItemData Then
                ComboListIndexByItemDate = i
                Exit Function
            End If
        Next i
    End With
    ComboListIndexByItemDate = -1
End Function

Public Function BtoStr(b As Boolean) As String

    If b Then
        BtoStr = "Y"
    End If
    
End Function

