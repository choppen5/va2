VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "vaDataAccess"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Member0" ,"class2"
Attribute VB_Ext_KEY = "Top_Level" ,"Yes"
Option Explicit

Public Enum enFolderType
    ftCollector = 1
    ftAnRule = 2
End Enum

Function copystatistic(CollectorID) As Integer

Dim rsResults As New adodb.Recordset
Dim insertrs As New adodb.Recordset

Dim con As New adodb.Connection



DB_CONNECTION_STRING = getconstring()
Dim strsql As String

Dim maxid As Integer
Dim ruledef As String
Dim error As String
Dim description As String
Dim Name As String
Dim parent_folder_id
Dim SftID
Dim HostID
Dim CompID


Dim currentcollector As adodb.Recordset

    strsql = "SELECT * FROM collector where collector_id = " & CollectorID

    Debug.Print "DB_CONNECTION_STRING = " & DB_CONNECTION_STRING
    con.Open DB_CONNECTION_STRING
    
    With rsResults
        .CursorLocation = adUseClient
        Call .Open(Source:=strsql, ActiveConnection:=con)
        Set .ActiveConnection = Nothing
    End With
    
    'maxid for new collector
    maxid = returnmaxid("collector_id", "collector")

    ruledef = Trim(padQuotes(rsResults("rule_def").Value & ""))
    error = Trim(padQuotes(rsResults("error").Value & ""))
    description = Trim(padQuotes(rsResults("description").Value & ""))
    Name = Trim(padQuotes(rsResults("Name").Value & ""))
    parent_folder_id = rsResults("parent_folder_id").Value
    If IsNull(parent_folder_id) Then parent_folder_id = "null"
    SftID = rsResults("sft_elmnt_id").Value
    If IsNull(SftID) Then SftID = "null"
    HostID = rsResults("host_id").Value
    If IsNull(HostID) Then HostID = "null"
    CompID = rsResults("monitored_comps_id").Value
    If IsNull(CompID) Then CompID = "null"

    strsql = "insert into collector (collector_id,type,rule_def,error,active,execution_interval,description,parent_folder_id,name,sft_elmnt_id,host_id,monitored_comps_id) values (" _
                                         & maxid & ",'" _
                                         & rsResults("type").Value & "','" _
                                         & ruledef & "','" _
                                         & error & "','" _
                                         & rsResults("active").Value & "'," _
                                         & rsResults("execution_interval").Value & ",'" _
                                         & description & "'," _
                                         & parent_folder_id & ",'" _
                                         & Name & "'," _
                                         & SftID & "," _
                                         & HostID & "," _
                                         & CompID _
                                         & ")"
                        
    
    With insertrs
            Debug.Print "strsql = " & strsql
                .CursorLocation = adUseClient
                Call .Open(Source:=strsql, ActiveConnection:=con)
                            
    End With

    'retun id from copy
    copystatistic = maxid

    

End Function

Sub importanalysisrule(filepath As String, Optional ByVal FolderID As Long = 0)
Dim dataset As New adodb.Recordset
Dim con As New adodb.Connection

Dim insertrs As New adodb.Recordset


DB_CONNECTION_STRING = getconstring()
Dim strsql As String

Debug.Print "DB_CONNECTION_STRING = " & DB_CONNECTION_STRING
con.Open DB_CONNECTION_STRING
                        
'On Error GoTo xmlerror

dataset.Open filepath

Dim maxid As Integer
Dim ruledef As String
Dim error As String
Dim description As String
Dim Name As String
Dim i As Integer

    If Not (dataset Is Nothing) Then
        If Not (dataset.BOF And dataset.EOF) Then
            dataset.MoveFirst
             
            Do While Not dataset.EOF
                 
                 
                maxid = returnmaxid("analysis_rule_id", "analysis_rule")
                ruledef = Trim(padQuotes(dataset("rule_def").Value & ""))
                error = Trim(padQuotes(dataset("error").Value & ""))
                description = Trim(padQuotes(dataset("description").Value & ""))
                Name = Trim(padQuotes(dataset("name").Value & ""))
                
                 
                strsql = "insert into analysis_rule (analysis_rule_id,type,rule_def,error,active,execution_interval,description,name,parent_folder_id) values (" _
                    & maxid & ",'" _
                    & dataset("type").Value & "','" _
                    & ruledef & "','" _
                    & error & "','" _
                    & dataset("active").Value & "'," _
                    & dataset("execution_interval").Value & ",'" _
                    & description & "','" _
                    & Name & "'," _
                    & IIf(FolderID = 0, "null", FolderID) _
                    & ")"
                
                                    
                With insertrs
                    Debug.Print "strsql = " & strsql
                    .CursorLocation = adUseClient
                    Call .Open(Source:=strsql, ActiveConnection:=con)
                
                End With
                         
                 
                dataset.MoveNext
            Loop
        End If
    End If

    Set insertrs.ActiveConnection = Nothing

xmlerror:
'Err.Raise Err.number, "Import Anallysis Rule XML Error ", Err.number

End Sub
Sub archivestatistic(oldcollectorid, newcollectorid)

Dim rsResults As New adodb.Recordset
Dim con As New adodb.Connection

Dim insertrs As New adodb.Recordset


DB_CONNECTION_STRING = getconstring()
Dim strsql As String

Debug.Print "DB_CONNECTION_STRING = " & DB_CONNECTION_STRING
con.Open DB_CONNECTION_STRING
                        

'1 - update old statvals to new ones
'2 - update new collector to have parent collector id



    strsql = "update stat_vals set collector_id = " & newcollectorid & " where collector_id = " & oldcollectorid
    
    Set rsResults = returndataset(strsql)

'retrieve name for coppied rule


    strsql = "select name from collector where collector_id = " & newcollectorid
    
    Set rsResults = returndataset(strsql)
    
    Dim oldname As String
    Dim sDate As String
    
    oldname = rsResults("name").Value
    sDate = Date
    oldname = sDate + "-" + oldname
    oldname = Left(oldname, 99)
    
    strsql = "update collector set name =  '" & oldname & "',parent_collector_id = " & oldcollectorid & " where collector_id = " & newcollectorid
    
    returndataset (strsql)
    
    'now update archived collector to have its parent id


End Sub


Sub importcollector(filepath As String, Optional ByVal FolderID As Long = 0, _
        Optional ByVal SftID As Long = 0, Optional ByVal HostID As Long = 0, Optional ByVal CompID As Long = 0)
Dim dataset As New adodb.Recordset
Dim con As New adodb.Connection

Dim insertrs As New adodb.Recordset


DB_CONNECTION_STRING = getconstring()
Dim strsql As String

Debug.Print "DB_CONNECTION_STRING = " & DB_CONNECTION_STRING
con.Open DB_CONNECTION_STRING
                        

On Error GoTo xmlerror

dataset.Open filepath

Dim maxid As Integer
Dim ruledef As String
Dim error As String
Dim description As String
Dim Name As String
Dim notimeout As String


Dim i As Integer
           If Not (dataset Is Nothing) Then
                If Not (dataset.BOF And dataset.EOF) Then
                    dataset.MoveFirst
                    
                    Do While Not dataset.EOF
                        
                           
                            maxid = returnmaxid("collector_id", "collector")
                            ruledef = Trim(padQuotes(dataset("rule_def").Value & ""))
                            error = Trim(padQuotes(dataset("error").Value & ""))
                            description = Trim(padQuotes(dataset("description").Value & ""))
                            Name = Trim(padQuotes(dataset("Name").Value & ""))
                            
                            
                            'notimeout = IIf(IsNull(dataset("name").value), "N", dataset("name").value)
                            
                            'will not import the notimeout parameter because vb freaks out here when importing xml file without it
                            
                            strsql = "insert into collector (collector_id,type,rule_def,error,active,execution_interval,description,name,parent_folder_id,sft_elmnt_id,host_id,monitored_comps_id) values (" _
                                & maxid & ",'" _
                                & dataset("type").Value & "','" _
                                & ruledef & "','" _
                                & error & "','" _
                                & dataset("active").Value & "'," _
                                & dataset("execution_interval").Value & ",'" _
                                & description & "','" _
                                & Name & "'," _
                                & IIf(FolderID = 0, "null", FolderID) & "," _
                                & IIf(SftID = 0, "null", SftID) & "," _
                                & IIf(HostID = 0, "null", HostID) & "," _
                                & IIf(CompID = 0, "null", CompID) _
                                & ")"
                                                
                            With insertrs
                                Debug.Print "strsql = " & strsql
                                .CursorLocation = adUseClient
                                 Call .Open(Source:=strsql, ActiveConnection:=con)
                            
                            End With
                                
                        
                        dataset.MoveNext
                    Loop
                End If
            End If
            
        Set insertrs.ActiveConnection = Nothing
xmlerror:
Debug.Print "could not import statistic + " & Err.number & Err.description
'Err.Raise Err.number, "Import Statistic Collector XML Error ", Err.number

End Sub




Sub makexml(ids As Variant, table_name, table_name_id, FileName As String)

Dim rsResults As adodb.Recordset
Dim con As New adodb.Connection

DB_CONNECTION_STRING = getconstring()
Dim strsql As String

Dim i As Integer

strsql = "select * from " & table_name & " where "

Dim wherestr As String
Dim orvar As String

Debug.Print "lbound = " & LBound(ids)
Debug.Print "ubound = " & UBound(ids)

For i = LBound(ids) To UBound(ids)
    
    
    If i = UBound(ids) Then
        orvar = " "
    Else
        orvar = " or "
    End If
    
    wherestr = wherestr & table_name_id & " = " & ids(i) & orvar

Next i

strsql = strsql & wherestr

Debug.Print "xml select str = " & strsql

'create array of ids, and table_name, file_name.  Pass to function create xml file based on array of ids and table name into file
Set rsResults = New adodb.Recordset
    Debug.Print "DB_CONNECTION_STRING = " & DB_CONNECTION_STRING
    con.Open DB_CONNECTION_STRING
    
    With rsResults
        .CursorLocation = adUseClient
        Call .Open(Source:=strsql, ActiveConnection:=con)
        Set .ActiveConnection = Nothing
    End With

On Error Resume Next 'try to erase old file
Kill FileName
rsResults.Save FileName, adPersistXML



End Sub


Public Function GetSoftMngSys() As adodb.Recordset

Dim rsResults As adodb.Recordset
Dim con As New adodb.Connection

 On Error GoTo ErrorHandler

DB_CONNECTION_STRING = getconstring()
Dim strsql As String

   ' On Error GoTo ErrorHandler
    
    strsql = "SELECT sft_mng_sys.name, sft_mng_sys.sft_mng_sys_id FROM sft_mng_sys"
    
    Set rsResults = New adodb.Recordset
    Debug.Print "DB_CONNECTION_STRING = " & DB_CONNECTION_STRING
    con.Open DB_CONNECTION_STRING
    
    With rsResults
        .CursorLocation = adUseClient
        Call .Open(Source:=strsql, ActiveConnection:=con)
        Set .ActiveConnection = Nothing
    End With
    
    Set GetSoftMngSys = rsResults
    
    Exit Function
    
ErrorHandler:
    MsgBox "data error! - SQL = " & strsql
End Function

Function del_child_sft_mng_sys(sft_mng_sys_id As Integer)

    Dim rsResults As adodb.Recordset
    Dim strsql As String
    
    DB_CONNECTION_STRING = getconstring()
    
    strsql = "select sft_elmnt_id from sft_elmnt where sft_mng_sys_id = " & sft_mng_sys_id
    Debug.Print "strSQL = " & strsql

    On Error GoTo ErrorHandler
    Set rsResults = returndataset(strsql)
    
    
    If Not (rsResults Is Nothing) Then
            If Not (rsResults.BOF And rsResults.EOF) Then
                    rsResults.MoveFirst
                    Do While Not rsResults.EOF
                        del_child_sft_elmnts (rsResults("sft_elmnt_id")) 'recursive function!
                    rsResults.MoveNext
                    Loop
                End If
    End If

    strsql = "delete from sft_mng_sys where sft_mng_sys_id = " & sft_mng_sys_id
    returndataset (strsql)

    Exit Function
    
ErrorHandler:
   MsgBox "data error! - SQL = " & strsql
    

End Function


Function del_child_sft_elmnts(sft_elmnt_id As Integer)

    Dim rsResults As adodb.Recordset
    Dim strsql As String
    
    DB_CONNECTION_STRING = getconstring()
    strsql = "select sft_elmnt_id from sft_elmnt where parent_elmnt_id = " & sft_elmnt_id
    Debug.Print "strSQL = " & strsql

    On Error GoTo ErrorHandler
    
    Set rsResults = returndataset(strsql)

    
    If Not (rsResults Is Nothing) Then
            If Not (rsResults.BOF And rsResults.EOF) Then
                    rsResults.MoveFirst
                    Do While Not rsResults.EOF
                        del_child_sft_elmnts (rsResults("sft_elmnt_id")) 'recursive function!
                    rsResults.MoveNext
                    Loop
                End If
    End If
    
    
    del_components_for_elmnt (sft_elmnt_id) 'function that deletes err defs for a component, then deltetes the component
    
    
    strsql = "delete from sft_elmnt_comp where sft_elmnt_id = " & sft_elmnt_id 'function that deletes sft_elmnt_comps
    returndataset (strsql)
    
    strsql = "delete from sft_err_deff where sft_elmnt_id = " & sft_elmnt_id
    returndataset (strsql)
    
    strsql = "delete from sft_elmnt where sft_elmnt_id = " & sft_elmnt_id
    returndataset (strsql)
    
    strsql = "delete from processes where sft_elmnt_id = " & sft_elmnt_id
    returndataset (strsql)
    
     strsql = "delete from monitored_comps where sft_elmnt_id = " & sft_elmnt_id
    returndataset (strsql)
    
    
    strsql = "delete from server_task where sft_elmnt_id = " & sft_elmnt_id
    returndataset (strsql)
    
     Exit Function
    
ErrorHandler:
   MsgBox "data error! - SQL = " & strsql
    

End Function




Function del_components_for_elmnt(sft_elmnt_id As Integer)

    Dim rsResults As adodb.Recordset
    Dim strsql As String
    
    DB_CONNECTION_STRING = getconstring()
    strsql = "select * from components where sft_elmnt_id = " & sft_elmnt_id
    
    Debug.Print "strSQL = " & strsql

    On Error GoTo ErrorHandler
    
    Set rsResults = returndataset(strsql)

    
    If Not (rsResults Is Nothing) Then
            If Not (rsResults.BOF And rsResults.EOF) Then
                    rsResults.MoveFirst
                    Do While Not rsResults.EOF
                        strsql = "delete from comp_errdef where components_id = " & rsResults("components_id").Value
                        returndataset (strsql)
                    rsResults.MoveNext
                    Loop
                End If
    End If
    
    
    strsql = "delete from components where sft_elmnt_id = " & sft_elmnt_id
    returndataset (strsql)
    
    
     Exit Function
    
ErrorHandler:
    MsgBox "data error! - SQL = " & strsql
    

End Function

Public Function returndataset(ByVal strsql As String) As adodb.Recordset

    Dim rsResults As adodb.Recordset
    Debug.Print "strSQL = " & strsql
    
    DB_CONNECTION_STRING = getconstring()
    
    On Error GoTo ErrorHandler

    Set rsResults = New adodb.Recordset

    With rsResults
        .CursorLocation = adUseClient
        Call .Open(Source:=strsql, ActiveConnection:=DB_CONNECTION_STRING)
        Set .ActiveConnection = Nothing
    End With
    
    Set returndataset = rsResults
    
    Exit Function
    
ErrorHandler:
    MsgBox "data error! - SQL = " & strsql
End Function


Public Function addhost(ByVal HostName As String, ByVal no_ping As String, Optional ByVal IPAddr As String) As Integer
On Error GoTo ErrorHandler
    Dim HostID As Integer
    Dim maxid
    Dim hostrecord As New adodb.Recordset
    Dim newrecord As New adodb.Recordset
    Dim strsql As String
    Dim newstrsql As String
    Dim lenmaxid As Integer

    strsql = "select max(host_id) ""max_host_id"" from host"

    DB_CONNECTION_STRING = getconstring()
    
    Debug.Print "strsql = " & strsql

    With hostrecord
        .CursorLocation = adUseClient
        Call .Open(Source:=strsql, ActiveConnection:=DB_CONNECTION_STRING)
        Set .ActiveConnection = Nothing
    End With

    ' lenmaxid = Len(maxid)

    maxid = hostrecord("max_host_id").Value & "" 'VB IS ABSOULTELY RETARTED!! FORCED TO CONCATANATE A "" STRING VALUE TO THIS.
                                                'If its NULL, VB WILL RECONGINZE IT AS "", because vb doesn't recognize  NULL BELOW
    If maxid = "" Then                                             'If its NULL, VB WILL RECONGINZE IT AS "", because vb doesn't recognize  NULL BELOW
         maxid = 1
    Else
         maxid = maxid + 1
    End If
   
   Debug.Print "max id =" & maxid

'    newstrsql = "insert into HOST(host_id,hostname,no_ping,ipaddress) VALUES" &
    newstrsql = "insert into host(host_id, hostname, ipaddress, no_ping) VALUES" & _
        "(" & maxid & ", " & _
        "'" & HostName & "'," & _
        "'" & IPAddr & "'," & _
        "'" & no_ping & "')"

    Debug.Print "insert sql = " & newstrsql
    
    With newrecord
        Call .Open(Source:=newstrsql, ActiveConnection:=DB_CONNECTION_STRING)
    End With

    Set hostrecord = Nothing
    Set newrecord = Nothing

    Exit Function

ErrorHandler:
    MsgBox "data error! - SQL = " & strsql
        'Err.Raise Err.number, "vaDataAccess.GetSoftMngSys", Err.number

End Function
Function add_sft_elmnt(istop As Integer, Optional ByVal parent_elmnt_id, Optional Name As String, Optional description As String, _
Optional sfttype As String, Optional Host As String, Optional installdir As String, Optional logdir As String, _
Optional exe As String, Optional service_name As String, Optional monitor_service As String, Optional restart_service As String, _
Optional send_event As String)

    Dim sysrecord As New adodb.Recordset
    Dim newrecord As New adodb.Recordset
    Dim strsql As String
    Dim maxid
    
    Dim newstrsql As String

    strsql = "select max(sft_elmnt_id) + 1 ""max_sft_elmnt_id"" from sft_elmnt"
    On Error GoTo ErrorHandler
    
    DB_CONNECTION_STRING = getconstring()
    Debug.Print "strsql = " & strsql
    
     
    With sysrecord
        .CursorLocation = adUseClient
        Call .Open(Source:=strsql, ActiveConnection:=DB_CONNECTION_STRING)
        Set .ActiveConnection = Nothing
    End With

   ' lenmaxid = Len(maxid)
   
    maxid = sysrecord("max_sft_elmnt_id").Value & "" 'VB IS ABSOULTELY RETARTED!! FORCED TO CONCATANATE A "" STRING VALUE TO THIS.
                                                'If its NULL, VB WILL RECONGINZE IT AS "", because vb doesn't recognize  NULL BELOW
    If maxid = "" Then                                             'If its NULL, VB WILL RECONGINZE IT AS "", because vb doesn't recognize  NULL BELOW
        maxid = 1
   Else
        maxid = maxid + 1
   End If
   Debug.Print "max id =" & maxid
 
    If istop = 1 Then 'if it is a top element, add a parent sft_mng_sys_id instead of a parent_elmnt_id
        
            newstrsql = "insert into sft_elmnt(sft_elmnt_id,sft_mng_sys_id,name,description,type,host,installdir,logdir," _
            & "exe,service_name,monitor_service,restart_service,send_event) values (" _
              & maxid & ",'" _
              & parent_elmnt_id & "','" _
              & Name & "','" _
              & description & "','" _
              & sfttype & "','" _
              & Host & "','" _
              & installdir & "','" _
              & logdir & "','" _
              & exe & "','" _
              & service_name & "','" _
              & monitor_service & "','" _
              & restart_service & "','" _
              & send_event & "')"
    
    Else ' we are not dealing with a top elemnt, insert a parent_elmnt_id instead
    
            newstrsql = "insert into sft_elmnt(sft_elmnt_id,parent_elmnt_id,name,description,type,host,installdir,logdir" _
            & ",exe,service_name,monitor_service,restart_service,send_event) values (" _
              & maxid & ",'" _
              & parent_elmnt_id & "','" _
              & Name & "','" _
              & description & "','" _
              & sfttype & "','" _
              & Host & "','" _
              & installdir & "','" _
              & logdir & "','" _
              & exe & "','" _
              & service_name & "','" _
              & monitor_service & "','" _
              & restart_service & "','" _
              & send_event & "')"
    End If

    Debug.Print "insert sql = " & newstrsql
    
     With newrecord
        Call .Open(Source:=newstrsql, ActiveConnection:=DB_CONNECTION_STRING)
    End With
    
  
    Set sysrecord = Nothing
    Set newrecord = Nothing
    
    
    
    Exit Function
    
ErrorHandler:
   MsgBox "data error! - SQL = " & newstrsql
        'Err.Raise Err.number, "vaDataAccess.GetSoftMngSys", Err.number

End Function

Function add_sft_elmnt_comp(ByVal Key As String, ByVal Value As String, ByVal sft_elmnt_id)

    Dim sysrecord As New adodb.Recordset
    Dim newrecord As New adodb.Recordset
    Dim strsql As String
    Dim maxid
    
    maxid = returnmaxid("sft_elmnt_comp_id", "sft_elmnt_comp")
    
    strsql = "insert into sft_elmnt_comp(sft_elmnt_comp_id,elmnt_key,elmnt_value,sft_elmnt_id ) values   ('" _
    & maxid & "','" & Key & "','" & Value & "','" & sft_elmnt_id & "')"

                                          
    DB_CONNECTION_STRING = getconstring()

    Debug.Print "insert sql = " & strsql
    
     With newrecord
        Call .Open(Source:=strsql, ActiveConnection:=DB_CONNECTION_STRING)
    End With
    
  
    Set sysrecord = Nothing
    Set newrecord = Nothing
    
    
    
    Exit Function
    
ErrorHandler:
           MsgBox "data error! - SQL = " & strsql


End Function

'Updates software element Option. Returns True - OK
Function upd_sft_elmnt_comp(ByVal Key As String, ByVal Value As String, ByVal sft_elmnt_comp_id As Long) As Boolean
On Error GoTo ErrorHandler

    Dim com As New adodb.Command

    'DB_CONNECTION_STRING = getconstring()

    With com
        If Len(Trim(Key)) > 0 Then          'Update Key
            .CommandText = "update sft_elmnt_comp set elmnt_key = ? where sft_elmnt_comp_id = ?"
            .Parameters.Append .CreateParameter("Key", adVarChar, adParamInput, 255, Key)
        ElseIf Len(Trim(Value)) > 0 Then    'Update Value
            .CommandText = "update sft_elmnt_comp set elmnt_value = ? where sft_elmnt_comp_id = ?"
            .Parameters.Append .CreateParameter("Value", adVarChar, adParamInput, 255, Value)
        Else
            Exit Function
        End If
        .Parameters.Append .CreateParameter("ID", adInteger, adParamInput, , sft_elmnt_comp_id)
        .ActiveConnection = DB_CONNECTION_STRING
        .Execute
        Set .ActiveConnection = Nothing
    End With
    upd_sft_elmnt_comp = True

    Exit Function
ErrorHandler:
    ErrorH 0
    Exit Function
End Function

'Deletes software element Option. Returns True - OK
Function del_sft_elmnt_comp(ByVal sft_elmnt_comp_id As Long) As Boolean
On Error GoTo ErrorHandler

    Dim com As New adodb.Command

    'DB_CONNECTION_STRING = getconstring()

    With com
        .CommandText = "delete sft_elmnt_comp where sft_elmnt_comp_id = ?"
        .Parameters.Append .CreateParameter("ID", adInteger, adParamInput, , sft_elmnt_comp_id)
        .ActiveConnection = DB_CONNECTION_STRING
        .Execute
        Set .ActiveConnection = Nothing
    End With
    del_sft_elmnt_comp = True

    Exit Function
ErrorHandler:
    ErrorH 0
    Exit Function
End Function



Function add_com_srvr_vals(ByVal Key As String, ByVal Value As String, ByVal com_srvr_vals_id)

'    Dim sysrecord As New adodb.Recordset
    Dim newrecord As New adodb.Recordset
    Dim strsql As String
    Dim maxid
    
    maxid = returnmaxid("com_srvr_vals_id", "com_srvr_vals")
    
    strsql = "insert into com_srvr_vals(com_srvr_vals_id,elmnt_key,elmnt_value,com_server_id ) values   ('" _
    & maxid & "','" & Key & "','" & Value & "','" & com_srvr_vals_id & "')"

                                          
    DB_CONNECTION_STRING = getconstring()

    Debug.Print "insert sql = " & strsql
    
    With newrecord
        Call .Open(Source:=strsql, ActiveConnection:=DB_CONNECTION_STRING)
    End With
    
  
'    Set sysrecord = Nothing
    Set newrecord = Nothing


    Exit Function
    
ErrorHandler:
    MsgBox "data error! - SQL = " & strsql


End Function

'Updates Communication Server Option. Returns True - OK
Function upd_com_srvr_vals(ByVal Key As String, ByVal Value As String, ByVal com_srvr_vals_id As Long) As Boolean
On Error GoTo ErrorHandler

    Dim com As New adodb.Command

    'DB_CONNECTION_STRING = getconstring()

    With com
        If Len(Trim(Key)) > 0 Then          'Update Key
            .CommandText = "update com_srvr_vals set elmnt_key = ? where com_srvr_vals_id = ?"
            .Parameters.Append .CreateParameter("Key", adVarChar, adParamInput, 255, Key)
        ElseIf Len(Trim(Value)) > 0 Then    'Update Value
            .CommandText = "update com_srvr_vals set elmnt_value = ? where com_srvr_vals_id = ?"
            .Parameters.Append .CreateParameter("Value", adVarChar, adParamInput, 255, Value)
        Else
            Exit Function
        End If
        .Parameters.Append .CreateParameter("ID", adInteger, adParamInput, , com_srvr_vals_id)
        .ActiveConnection = DB_CONNECTION_STRING
        .Execute
        Set .ActiveConnection = Nothing
    End With
    upd_com_srvr_vals = True

    Exit Function
ErrorHandler:
    ErrorH 0
    Exit Function
End Function

'Deletes Communication Server Option. Returns True - OK
Function del_com_srvr_vals(ByVal com_srvr_vals_id As Long) As Boolean
On Error GoTo ErrorHandler

    Dim com As New adodb.Command

    'DB_CONNECTION_STRING = getconstring()

    With com
        .CommandText = "delete com_srvr_vals where com_srvr_vals_id = ?"
        .Parameters.Append .CreateParameter("ID", adInteger, adParamInput, , com_srvr_vals_id)
        .ActiveConnection = DB_CONNECTION_STRING
        .Execute
        Set .ActiveConnection = Nothing
    End With
    del_com_srvr_vals = True

    Exit Function
ErrorHandler:
    ErrorH 0
    Exit Function
End Function


Function addnotifcation_rule(ByVal Name As String, ByVal message As String, _
ByVal notify_all As String, ByVal notetype, ByVal ev_event_sub_type, _
ByVal ev_event_level, ByVal ev_event_string, ByVal active As String)
On Error GoTo ErrorHandler
    Dim sysrecord As New adodb.Recordset
    Dim newrecord As New adodb.Recordset
    Dim strsql As String
    Dim maxid

    If ev_event_level = "" Or IsNull(ev_event_level) Then
        ev_event_level = 0
    End If


'On Error GoTo errorhandler
    maxid = returnmaxid("note_rule_id", "notification_rule")
    
    strsql = "insert into notification_rule( " _
    & "note_rule_id," _
    & "name," _
    & "message," _
    & "notify_all," _
    & "type, " _
    & " ev_event_sub_type," _
    & "ev_event_level," _
    & "ev_event_string," _
    & "active) values   (" _
    & maxid & ",'" _
    & Name & "','" _
    & message & "','" _
    & notify_all & "','" _
    & notetype & "','" _
    & ev_event_sub_type & "'," _
    & ev_event_level & ",'" _
    & ev_event_string & "','" _
    & active & "')"

                                         
    DB_CONNECTION_STRING = getconstring()

    Debug.Print "insert sql = " & strsql
    
    With newrecord
        Call .Open(Source:=strsql, ActiveConnection:=DB_CONNECTION_STRING)
    End With
    
  
    Set sysrecord = Nothing
    Set newrecord = Nothing
    
    addnotifcation_rule = maxid
    
    Exit Function
    
ErrorHandler:
    ErrorH 0
    Exit Function
    'MsgBox "data error! - SQL = " & strsql

End Function
Function add_schedule(ByVal schd_name As String, ByVal schedule_every As String, ByVal every_day As String, _
ByVal monday As String, ByVal tuesday As String, ByVal wedensday As String, ByVal thursday As String, ByVal friday As String, _
ByVal saturday As String, ByVal sunday As String, ByVal hour_start As String, ByVal minute_start As String, ByVal hour_end As String, _
ByVal minute_end As String) As Long

    Dim sysrecord As New adodb.Recordset
    Dim newrecord As New adodb.Recordset
    Dim strsql As String
    Dim maxid
    
    maxid = returnmaxid("schedule_id", "schedule")
    
    DB_CONNECTION_STRING = getconstring()
    
    strsql = "insert into schedule(schedule_id,schd_name,schedule_every,every_day,monday,tuesday,wednesday,thursday," _
    & "friday,saturday,sunday,hour_start,minute_start,hour_end,minute_end) values (" _
    & maxid & ",'" _
    & schd_name & "','" _
    & schedule_every & "','" _
    & every_day & "','" _
    & monday & "','" _
    & tuesday & "','" _
    & wedensday & "','" _
    & thursday & "','" _
    & friday & "','" _
    & saturday & "','" _
    & sunday & "','" _
    & hour_start & "','" _
    & minute_start & "','" _
    & hour_end & "','" _
    & minute_end & "')"

    Debug.Print "insert sql = " & strsql
    
    With newrecord
        Call .Open(Source:=strsql, ActiveConnection:=DB_CONNECTION_STRING)
    End With

    add_schedule = maxid

    Set sysrecord = Nothing
    Set newrecord = Nothing
    
    Exit Function
    
ErrorHandler:
        MsgBox "data error! - SQL = " & strsql
End Function

Function add_collector(ByVal Name As String, ByVal atype As String, ByVal rule_def As String, ByVal active As String, _
  ByVal sNoTimeOut As String, ByVal execution_interval, ByVal description, Optional ByVal FolderID As Long = 0, _
  Optional ByVal SftID As Long = 0, Optional ByVal HostID As Long = 0, Optional ByVal CompID As Long = 0) As Integer

    Dim sysrecord As New adodb.Recordset
    Dim newrecord As New adodb.Recordset
    Dim strsql As String
    Dim maxid
    
    maxid = returnmaxid("collector_id", "collector")
    DB_CONNECTION_STRING = getconstring()
    
    strsql = "insert into collector(collector_id,name,type,rule_def,active,notimeout,execution_interval,description,parent_folder_id,sft_elmnt_id,host_id,monitored_comps_id) values (" _
    & maxid & ",'" _
    & Name & "','" _
    & atype & "','" _
    & rule_def & "','" _
    & active & "','" _
    & sNoTimeOut & "','" _
    & execution_interval & "','" _
    & description & "'," _
    & IIf(FolderID = 0, "null", FolderID) & "," _
    & IIf(SftID = 0, "null", SftID) & "," _
    & IIf(HostID = 0, "null", HostID) & "," _
    & IIf(CompID = 0, "null", CompID) _
    & ")"
    '01/25/2004:Somu Added "sNoTimeOut" and modified related code.


    Debug.Print "insert sql = " & strsql
    
     With newrecord
        Call .Open(Source:=strsql, ActiveConnection:=DB_CONNECTION_STRING)
    End With
    
  
    Set sysrecord = Nothing
    Set newrecord = Nothing
    
    add_collector = maxid
    
    Exit Function
    
ErrorHandler:
       MsgBox "data error! - SQL = " & strsql
End Function

Function add_analysis_rule(ByVal Name As String, ByVal atype As String, ByVal rule_def As String, ByVal active As String, ByVal sNoTimeOut As String, ByVal description As String, ByVal execution_interval, Optional ByVal FolderID As Long = 0) As Integer

    Dim sysrecord As New adodb.Recordset
    Dim newrecord As New adodb.Recordset
    Dim strsql As String
    Dim maxid
    
    maxid = returnmaxid("analysis_rule_id", "analysis_rule")
    DB_CONNECTION_STRING = getconstring()
    
    strsql = "insert into analysis_rule(analysis_rule_id,name,type,rule_def,execution_interval,description,active,notimeout,parent_folder_id) values (" _
    & maxid & ",'" _
    & Name & "','" _
    & atype & "','" _
    & rule_def & "','" _
    & execution_interval & "','" _
    & description & "','" _
    & active & "','" _
    & sNoTimeOut & "'," _
    & IIf(FolderID = 0, "null", FolderID) _
    & ")"
    '01/25/2004:Somu Added "sNoTimeOut" and modified related code.

    Debug.Print "insert sql = " & strsql
    
    With newrecord
        Call .Open(Source:=strsql, ActiveConnection:=DB_CONNECTION_STRING)
    End With

    Set sysrecord = Nothing
    Set newrecord = Nothing
    
    add_analysis_rule = maxid
    
    Exit Function
    
ErrorHandler:
    MsgBox "data error! - SQL = " & strsql
End Function

Function copy_analysis_rule(ByVal analysis_rule_id As Long) As Integer

    Dim com As New adodb.Command
    Dim strsql As String
    Dim maxid
    
    maxid = returnmaxid("analysis_rule_id", "analysis_rule")
    DB_CONNECTION_STRING = getconstring()

    With com
        .CommandText = "insert into analysis_rule(analysis_rule_id,name,type,rule_def,execution_interval,description,active,notimeout,parent_folder_id) " & _
            "select ?,name,type,rule_def,execution_interval,description,active,notimeout,parent_folder_id from analysis_rule where analysis_rule_id=?"
        .Parameters.Append .CreateParameter("new_analysis_rule_id", adInteger, adParamInput, , maxid)
        .Parameters.Append .CreateParameter("analysis_rule_id", adInteger, adParamInput, , analysis_rule_id)
        .ActiveConnection = DB_CONNECTION_STRING
        .Execute
    End With
    
    Set com = Nothing

    copy_analysis_rule = maxid

    Exit Function

ErrorHandler:
    MsgBox "data error! - SQL = " & strsql
End Function


Function add_system_msg(ByVal msgtype As String, Optional ByVal message As String)

    Dim sysrecord As New adodb.Recordset
    Dim newrecord As New adodb.Recordset
    Dim strsql As String
    Dim maxid
    
    maxid = returnmaxid("system_msg_id", "system_msg")
    DB_CONNECTION_STRING = getconstring()
    
    strsql = "insert into system_msg(system_msg_id,type,message) values (" _
    & maxid & ",'" _
    & msgtype & "','" _
    & message & "')"


    Debug.Print "insert sql = " & strsql
    
     With newrecord
        Call .Open(Source:=strsql, ActiveConnection:=DB_CONNECTION_STRING)
    End With
    
  
    Set sysrecord = Nothing
    Set newrecord = Nothing
    
    Exit Function
    
ErrorHandler:
        MsgBox "data error! - SQL = " & strsql
End Function

Function add_component(ByVal pid As Integer, ByVal cc_alias As String, Optional ByVal description As String)

    Dim sysrecord As New adodb.Recordset
    Dim newrecord As New adodb.Recordset
    Dim strsql As String
    Dim maxid
    
 On Error GoTo ErrorHandler
    maxid = returnmaxid("components_id", "components")
    DB_CONNECTION_STRING = getconstring()
    
    strsql = "insert into components(components_id,cc_alias,description,sft_elmnt_id) values (" _
    & maxid & ",'" _
    & cc_alias & "','" _
    & description & "','" _
    & pid & "')"

    Debug.Print "insert sql = " & strsql
    
     With newrecord
        Call .Open(Source:=strsql, ActiveConnection:=DB_CONNECTION_STRING)
    End With
    
  
    Set sysrecord = Nothing
    Set newrecord = Nothing
    
    Exit Function
    
ErrorHandler:
        MsgBox "data error! - SQL = " & strsql
End Function

Function add_data_source(ByVal Name, ByVal username, ByVal password, ByVal alias)
    Dim sysrecord As New adodb.Recordset
    Dim newrecord As New adodb.Recordset
    Dim strsql As String
    Dim maxid
    
 On Error GoTo ErrorHandler
    maxid = returnmaxid("data_source_id", "data_source")
    DB_CONNECTION_STRING = getconstring()
    
    strsql = "insert into data_source(data_source_id,name,username,password,alias) values (" _
    & maxid & ",'" _
    & Name & "','" _
    & username & "','" _
    & password & "','" _
    & alias & "')" _
    
    Debug.Print "insert sql = " & strsql
    
     With newrecord
        Call .Open(Source:=strsql, ActiveConnection:=DB_CONNECTION_STRING)
    End With
    
  
    Set sysrecord = Nothing
    Set newrecord = Nothing
    
    Exit Function
    
ErrorHandler:
       MsgBox "data error! - SQL = " & strsql


End Function


Function add_administrators(ByVal first_name As String, ByVal last_name As String, ByVal email As String, ByVal phone As String, _
                            ByVal Pager As String) As Long

    Dim sysrecord As New adodb.Recordset
    Dim newrecord As New adodb.Recordset
    Dim strsql As String
    Dim maxid
    
    maxid = returnmaxid("administrators_id", "administrators")
    DB_CONNECTION_STRING = getconstring()

On Error GoTo ErrorHandler
    strsql = "insert into administrators(administrators_id,first_name,last_name,email,phone,pager) " _
    & " values (" _
    & maxid & ",'" _
    & first_name & "','" _
    & last_name & "','" _
    & email & "','" _
    & phone & "','" _
    & Pager & "')" _

    '& schedule_id & " ')"

    Debug.Print "insert sql = " & strsql

    With newrecord
        Call .Open(Source:=strsql, ActiveConnection:=DB_CONNECTION_STRING)
    End With

    add_administrators = maxid

    Set sysrecord = Nothing
    Set newrecord = Nothing

    Exit Function

ErrorHandler:
        MsgBox "data error! - SQL = " & strsql
End Function

Function add_comunicationserver(ByVal Name As String, ByVal smtp_server As String, ByVal ctype As String, Optional ByVal Port As Long) As Long

    Dim sysrecord As New adodb.Recordset
    Dim newrecord As New adodb.Recordset
    Dim strsql As String
    Dim maxid
    
 'On Error GoTo errorhandler
    maxid = returnmaxid("com_server_id", "comunicationserver")
    DB_CONNECTION_STRING = getconstring()
    
    strsql = "insert into comunicationserver(com_server_id,name,smtp_server,type) values (" & maxid & ",'" & Name & _
    "','" & smtp_server & "','" & ctype & "')"


    Debug.Print "insert sql = " & strsql
    
     With newrecord
        Call .Open(Source:=strsql, ActiveConnection:=DB_CONNECTION_STRING)
    End With

    add_comunicationserver = maxid

    Set sysrecord = Nothing
    Set newrecord = Nothing

    Exit Function
    
ErrorHandler:
        MsgBox "data error! - SQL = " & strsql
End Function

Function add_reaction(ByVal Name As String, ByVal rtype As String, ByVal rule_def As String, ByVal hostspecific As String, _
            ByVal active As String, ByVal sv_name As String, ByVal ErrorText As String)

On Error GoTo ErrorHandler

    Dim sysrecord As New adodb.Recordset
    Dim newrecord As New adodb.Recordset
    Dim strsql As String
    Dim maxid

    maxid = returnmaxid("reaction_id", "reaction")
    DB_CONNECTION_STRING = getconstring()
    
    strsql = "insert into reaction(reaction_id,name,type,rule_def,host_specific,active,sv_name,error) values (" & maxid & ",'" & Name & _
    "','" & rtype & "','" & rule_def & "','" & hostspecific & "','" & active & "','" & sv_name & "','" & padQuotes(ErrorText) & "')"

    Debug.Print "insert sql = " & strsql
    
    With newrecord
        Call .Open(Source:=strsql, ActiveConnection:=DB_CONNECTION_STRING)
    End With

    Set sysrecord = Nothing
    Set newrecord = Nothing

    add_reaction = maxid

    Exit Function

ErrorHandler:
      MsgBox "data error! - SQL = " & strsql
End Function

Function addsft_error_def(ByVal Name As String, ByVal search_string As String, ByVal ev_type, ev_level, ev_sub_type) As Long
    
    Dim sysrecord As New adodb.Recordset
    Dim newrecord As New adodb.Recordset
    Dim strsql As String
    Dim maxid

 On Error GoTo ErrorHandler
    maxid = returnmaxid("error_defs_id", "sft_error_defs")
    DB_CONNECTION_STRING = getconstring()
    
    strsql = "insert into  sft_error_defs(error_defs_id,name,search_string,ev_type,ev_level,ev_sub_type) " _
    & "values (" & maxid & ",'" & Name & "','" _
    & search_string & "','" _
     & ev_type & "'," _
     & ev_level & ",'" _
      & ev_sub_type & "')"

    Debug.Print "insert sql = " & strsql

     With newrecord
        Call .Open(Source:=strsql, ActiveConnection:=DB_CONNECTION_STRING)
    End With

    Set sysrecord = Nothing
    Set newrecord = Nothing

    addsft_error_def = maxid

    Exit Function

ErrorHandler:
        MsgBox "data error! - SQL = " & strsql
End Function

Function returnmaxid(ByVal idfield As String, ByVal table As String) As Integer

    Dim sysrecord As New adodb.Recordset
    Dim newrecord As New adodb.Recordset
    Dim strsql As String
    Dim maxid
    
' On Error GoTo errorhandler
    
    Dim newstrsql As String
    DB_CONNECTION_STRING = getconstring()
    
    strsql = "select max(" & idfield & " ) """ & idfield & """ from " & table
    'On Error GoTo errorhandler
    
    Debug.Print "strsql = " & strsql
    
     
    With sysrecord
        .CursorLocation = adUseClient
        Call .Open(Source:=strsql, ActiveConnection:=DB_CONNECTION_STRING)
        Set .ActiveConnection = Nothing
    End With

   ' lenmaxid = Len(maxid)
   
    maxid = sysrecord(idfield).Value  'VB IS ABSOULTELY RETARTED!! FORCED TO CONCATANATE A "" STRING VALUE TO THIS.
                                                
   If maxid = "" Or IsNull(maxid) Then                                              'If its NULL, VB WILL RECONGINZE IT AS "", because vb doesn't recognize  NULL BELOW
        maxid = 1
   Else
        maxid = maxid + 1
   End If
   
   Debug.Print "max id =" & maxid
   
   returnmaxid = maxid
   
   Set sysrecord = Nothing
    Set newrecord = Nothing

Exit Function

ErrorHandler:
        MsgBox "data error! - SQL = " & strsql



End Function

Function addsys(ByVal Name As String)

    Dim sysrecord As New adodb.Recordset
    Dim newrecord As New adodb.Recordset
    Dim strsql As String
    Dim maxid


    Dim newstrsql As String
    DB_CONNECTION_STRING = getconstring()
    
    strsql = "select max(sft_mng_sys_id) ""max_sft_mng_sys_id"" from sft_mng_sys"
On Error GoTo ErrorHandler
    
    
    Debug.Print "strsql = " & strsql
    
     
    With sysrecord
        .CursorLocation = adUseClient
        Call .Open(Source:=strsql, ActiveConnection:=DB_CONNECTION_STRING)
        Set .ActiveConnection = Nothing
    End With

   ' lenmaxid = Len(maxid)
   
    maxid = sysrecord("max_sft_mng_sys_id").Value & "" 'VB IS ABSOULTELY RETARTED!! FORCED TO CONCATANATE A "" STRING VALUE TO THIS.
                                                'If its NULL, VB WILL RECONGINZE IT AS "", because vb doesn't recognize  NULL BELOW

    If maxid = "" Or IsNull(maxid) Then                                             'If its NULL, VB WILL RECONGINZE IT AS "", because vb doesn't recognize  NULL BELOW
        maxid = 1
   Else
        maxid = maxid + 1
   End If
   
   Debug.Print "max id =" & maxid
 
    
            newstrsql = "insert into sft_mng_sys(sft_mng_sys_id,name) VALUES" & _
    "(" & maxid & ", " & _
    "'" & Name & "')"


    Debug.Print "insert sql = " & newstrsql
    
     With newrecord
        Call .Open(Source:=newstrsql, ActiveConnection:=DB_CONNECTION_STRING)
    End With
    
  
    Set sysrecord = Nothing
    Set newrecord = Nothing
    
    
    
    Exit Function
    
ErrorHandler:
       MsgBox "data error! - SQL = " & strsql


End Function


Function editsys(ByVal sysid As Integer, Name As String)

    Dim sysrecord As New adodb.Recordset
    Dim newrecord As New adodb.Recordset
    Dim strsql As String
    Dim maxid
    
    Dim newstrsql As String

 On Error GoTo ErrorHandler
    DB_CONNECTION_STRING = getconstring()
    
    newstrsql = "update sft_mng_sys set name = '" & Name & "' where sft_mng_sys_id = " & sysid

    Debug.Print "update sql = " & newstrsql
    
     With newrecord
        Call .Open(Source:=newstrsql, ActiveConnection:=DB_CONNECTION_STRING)
    End With
    
  
    Set sysrecord = Nothing
    
    Exit Function
    
ErrorHandler:
        MsgBox "data error! - SQL = " & strsql


End Function


Function editsft_elmnt(ByVal sft_elmnt_id As Integer, Optional Name As String, Optional description As String, _
Optional sfttype As String, Optional Host As String, Optional installdir As String, Optional logdir As String, _
Optional exe As String, Optional service_name As String, Optional monitor_service As String, Optional restart_service As String, _
Optional send_event As String)

    Dim sysrecord As New adodb.Recordset
    Dim newrecord As New adodb.Recordset
    Dim strsql As String
    Dim maxid

 On Error GoTo ErrorHandler
    Dim newstrsql As String

    DB_CONNECTION_STRING = getconstring()
    
    newstrsql = "update sft_elmnt set name = '" & Name & "', " _
    & "description = '" & description & "', " _
    & "type = '" & sfttype & "', " _
    & "host = '" & Host & "', " _
    & "installdir = '" & installdir & "', " _
    & "logdir = '" & logdir & "', " _
    & "exe = '" & exe & "', " _
    & "service_name = '" & service_name & "', " _
    & "monitor_service = '" & monitor_service & "', " _
    & "restart_service = '" & restart_service & "', " _
    & "send_event = '" & send_event & "' " _
    & "Where sft_elmnt_id = " & sft_elmnt_id

    Debug.Print "update sql = " & newstrsql
    
     With newrecord
        Call .Open(Source:=newstrsql, ActiveConnection:=DB_CONNECTION_STRING)
    End With
    
  
    Set sysrecord = Nothing
    
    Exit Function
    
ErrorHandler:
        MsgBox "data error! - SQL = " & strsql


End Function


Function splitval(nodename, Key As String, arraynum As Integer) As Variant
Dim idarray As Variant 'array
Dim pid
Dim etype
Dim retval

If InStr(nodename, "~") Then
    idarray = Split(nodename, Key)
    pid = idarray(0)
    etype = idarray(1)
    etype = Trim(etype)
    
    If arraynum = 1 Then
        retval = pid
    ElseIf arraynum = 2 Then
        retval = etype
    End If
Else
    retval = nodename
End If
                
splitval = retval


End Function

Function returnitemtype(itemkey) As Variant 'returns itemtype, after 2nd ~
Dim idarray As Variant 'array
Dim etype
Dim itemtype
Dim retval

If InStr(itemkey, "~") Then
    idarray = Split(itemkey, "~")
    itemtype = idarray(2)
    retval = itemtype
Else
    retval = itemkey
End If

returnitemtype = retval

End Function

Function padQuotes(instring)
Rem This function pads an extra single quote in strings containing
Rem quotes for proper SQL searching.

Dim bodybuild
Dim bodystring
Dim Length
Dim i

bodybuild = ""
bodystring = instring
Length = Len(bodystring)
For i = 1 To Length
   bodybuild = bodybuild & Mid(bodystring, i, 1)
   If Mid(bodystring, i, 1) = Chr(39) Then
      bodybuild = bodybuild & Mid(bodystring, i, 1)
   End If
Next
bodystring = bodybuild
padQuotes = bodystring
End Function

'allsystems(indexfield).value

Function getconstring() As String
    
    Dim dns As String
    Dim pwd As String
    Dim uid As String
    
    uid = GetRegSetting(HKEY_LOCAL_MACHINE, APPKEY, "UID", "")
    pwd = GetRegSetting(HKEY_LOCAL_MACHINE, APPKEY, "PWD", "")
    dns = GetRegSetting(HKEY_LOCAL_MACHINE, APPKEY, "DNS", "")
    
    getconstring = "DSN=" & dns & ";UID=" & uid & ";PWD=" & pwd

End Function

Function create_comp_err() As adodb.Recordset

Dim rsCreate As adodb.Recordset

On Error GoTo ErrorHandler
    
    Set rsCreate = CreateObject("ADODB.Recordset")
    With rsCreate
        .Fields.Append "components_id", adInteger
        .Fields.Append "error_defs_id", adInteger
        .Fields.Append "choiceID", adVarChar, 50
        .Open
    End With

    
    Set create_comp_err = rsCreate
    
    Exit Function
    
ErrorHandler:
    MsgBox "data error!"
    

End Function

Function TestConnectString(ByVal sConn As String) As Boolean
    On Error Resume Next

        Dim cnn As adodb.Connection
        Set cnn = New adodb.Connection
        
        'TestConnectString initializes to False by default
        cnn.Open sConn
    
        'No error means that the connect string works!
        If Err.number = 0 Then TestConnectString = True
    
        ' Clean up and release resources
        cnn.Close
        Set cnn = Nothing

    End Function

'Returns recordset with admins
Public Function GetAdminsList() As Recordset
On Error GoTo ErrorHandler

    Dim rs As New adodb.Recordset

    DB_CONNECTION_STRING = getconstring()

    With rs
        .CursorLocation = adUseClient
        .Open "select administrators_id, first_name, last_name from administrators order by first_name, last_name", DB_CONNECTION_STRING, adOpenForwardOnly
        Set .ActiveConnection = Nothing
    End With
    Set GetAdminsList = rs

    Exit Function
ErrorHandler:
    ErrorH 0
    Exit Function
End Function

'Returns recordset with schedules
Public Function GetSchedList() As Recordset
On Error GoTo ErrorHandler

    Dim rs As New adodb.Recordset

    DB_CONNECTION_STRING = getconstring()
    
    With rs
        .CursorLocation = adUseClient
        .Open "select schedule_id, schd_name from schedule order by schd_name", DB_CONNECTION_STRING, adOpenForwardOnly
        Set .ActiveConnection = Nothing
    End With
    Set GetSchedList = rs

    Exit Function
ErrorHandler:
    ErrorH 0
    Exit Function
End Function

'Returns recordset with Process
Public Function GetProcess(ByVal process_id As Long) As Recordset
On Error GoTo ErrorHandler

    Dim rs As New adodb.Recordset
    Dim com As New adodb.Command

    DB_CONNECTION_STRING = getconstring()

    With com
        .CommandText = "select process_id, pid, task_id, process, memory, virtualmem, cc_alias, cc_name, pagefaults from processes where process_id=?"
        .Parameters.Append .CreateParameter("process_id", adInteger, adParamInput, , process_id)
        .ActiveConnection = DB_CONNECTION_STRING
    End With
    With rs
        .CursorLocation = adUseClient
        .Open com, , adOpenStatic, adLockReadOnly
        Set .ActiveConnection = Nothing
    End With
    If rs.RecordCount > 0 Then
        Set GetProcess = rs
    Else
        rs.Close
    End If

    Exit Function
ErrorHandler:
    ErrorH 0
    Exit Function
End Function

'Returns recordset with Server Task
Public Function GetServerTask(ByVal server_task_id As Long) As Recordset
On Error GoTo ErrorHandler

    Dim rs As New adodb.Recordset
    Dim com As New adodb.Command

    DB_CONNECTION_STRING = getconstring()

    With com
        .CommandText = "select tk_taskid, cc_alias, tk_pid, cc_runmode, tk_disp_runstate, tk_status, tk_start_time, tk_end_time from server_task where server_task_id=?"
        .Parameters.Append .CreateParameter("server_task_id", adInteger, adParamInput, , server_task_id)
        .ActiveConnection = DB_CONNECTION_STRING
    End With
    With rs
        .CursorLocation = adUseClient
        .Open com, , adOpenStatic, adLockReadOnly
        Set .ActiveConnection = Nothing
    End With
    If rs.RecordCount > 0 Then
        Set GetServerTask = rs
    Else
        rs.Close
    End If

    Exit Function
ErrorHandler:
    ErrorH 0
    Exit Function
End Function

'Returns recordset with Session
Public Function GetSession(ByVal sessions_id As Long) As Recordset
On Error GoTo ErrorHandler

    Dim rs As New adodb.Recordset
    Dim com As New adodb.Command

    DB_CONNECTION_STRING = getconstring()

    With com
        .CommandText = "select * from sessions where sessions_id=?"
        .Parameters.Append .CreateParameter("sessions_id", adInteger, adParamInput, , sessions_id)
        .ActiveConnection = DB_CONNECTION_STRING
    End With
    With rs
        .CursorLocation = adUseClient
        .Open com, , adOpenStatic, adLockReadOnly
        Set .ActiveConnection = Nothing
    End With
    If rs.RecordCount > 0 Then
        Set GetSession = rs
    Else
        rs.Close
    End If

    Exit Function
ErrorHandler:
    ErrorH 0
    Exit Function
End Function

'Returns recordset with Monitored Comps
Public Function GetMonitoredComps(ByVal monitored_comps_id As Long) As Recordset
On Error GoTo ErrorHandler

    Dim rs As New adodb.Recordset
    Dim com As New adodb.Command

    DB_CONNECTION_STRING = getconstring()

    With com
        .CommandText = "select cc_name, cc_alias, cp_disp_run_state, cp_num_run, cp_max_tas, cp_actv_mt, cp_start_time, cp_end_time from monitored_comps where monitored_comps_id=?"
        .Parameters.Append .CreateParameter("monitored_comps_id", adInteger, adParamInput, , monitored_comps_id)
        .ActiveConnection = DB_CONNECTION_STRING
    End With
    With rs
        .CursorLocation = adUseClient
        .Open com, , adOpenStatic, adLockReadOnly
        Set .ActiveConnection = Nothing
    End With
    If rs.RecordCount > 0 Then
        Set GetMonitoredComps = rs
    Else
        rs.Close
    End If

    Exit Function
ErrorHandler:
    ErrorH 0
    Exit Function
End Function

'Adds link between admin and comm server
Public Function add_com_admin_link(ByVal AdminID As Long, ByVal SrvID As Long) As Boolean
On Error GoTo ErrorHandler

    Dim com As New adodb.Command

    DB_CONNECTION_STRING = getconstring()
    
    With com
        .CommandText = "insert into com_admin(administrators_id, com_server_id) values (?, ?)"
        .Parameters.Append .CreateParameter("AdminID", adInteger, adParamInput, , AdminID)
        .Parameters.Append .CreateParameter("SrvID", adInteger, adParamInput, , SrvID)
        .ActiveConnection = DB_CONNECTION_STRING
        .Execute
        Set .ActiveConnection = Nothing
    End With
    add_com_admin_link = True

    Exit Function
ErrorHandler:
    ErrorH 0
    Exit Function
End Function

'Adds admin to Schedule
Public Function add_admin_schedule(ByVal AdminID As Long, ByVal SchID As Long) As Boolean
On Error GoTo ErrorHandler

    Dim com As New adodb.Command

    DB_CONNECTION_STRING = getconstring()
    
    With com
        .CommandText = "update administrators set schedule_id = ? where administrators_id = ?"
        .Parameters.Append .CreateParameter("SchID", adInteger, adParamInput, , SchID)
        .Parameters.Append .CreateParameter("AdminID", adInteger, adParamInput, , AdminID)
        .ActiveConnection = DB_CONNECTION_STRING
        .Execute
        Set .ActiveConnection = Nothing
    End With
    add_admin_schedule = True

    Exit Function
ErrorHandler:
    ErrorH 0
    Exit Function
End Function

'Returns recordset with Analysis rules
Public Function GetAnRulesList() As Recordset
On Error GoTo ErrorHandler

    Set GetAnRulesList = returndataset("select analysis_rule_id, name from analysis_rule order by name")

    Exit Function
ErrorHandler:
    ErrorH 0
    Exit Function
End Function

'Returns recordset with Reactions
Public Function GetReactionsList() As Recordset
On Error GoTo ErrorHandler

    Set GetReactionsList = returndataset("select reaction_id, name from reaction order by name")

    Exit Function
ErrorHandler:
    ErrorH 0
    Exit Function
End Function

'Returns recordset with Hosts
Public Function GetHostsList() As Recordset
On Error GoTo ErrorHandler

    Set GetHostsList = returndataset("select host_id, hostname from host order by hostname")

    Exit Function
ErrorHandler:
    ErrorH 0
    Exit Function
End Function

'Returns recordset with Seibel servers
Public Function GetSeibelList() As Recordset
On Error GoTo ErrorHandler

    Set GetSeibelList = returndataset("select name from sft_elmnt where type = 'appserver' order by name")

    Exit Function
ErrorHandler:
    ErrorH 0
    Exit Function
End Function

'Adds Error Event to Analysis Rule
Public Function add_error_AnRule(ByVal AnRuleID As Long, ByVal ErrID As Long) As Boolean
On Error GoTo ErrorHandler

    Dim com As New adodb.Command

    DB_CONNECTION_STRING = getconstring()

    With com
        .CommandText = "insert into analysis_errdef (analysis_rule_id, error_defs_id) values (?, ?)"
        .Parameters.Append .CreateParameter("AnRuleID", adInteger, adParamInput, , AnRuleID)
        .Parameters.Append .CreateParameter("ErrID", adInteger, adParamInput, , ErrID)
        .ActiveConnection = DB_CONNECTION_STRING
        .Execute
        Set .ActiveConnection = Nothing
    End With
    add_error_AnRule = True

    Exit Function
ErrorHandler:
    ErrorH 0
    Exit Function
End Function

'Adds Error Reaction to Notification Rule
Public Function add_Reaction_NotRule(ByVal NotRuleID As Long, ByVal ReactID As Long) As Boolean
On Error GoTo ErrorHandler

    Dim com As New adodb.Command

    DB_CONNECTION_STRING = getconstring()

    With com
        .CommandText = "insert into notification_reaction (note_rule_id, reaction_id) values (?, ?)"
        .Parameters.Append .CreateParameter("NotRuleID", adInteger, adParamInput, , NotRuleID)
        .Parameters.Append .CreateParameter("ReactID", adInteger, adParamInput, , ReactID)
        .ActiveConnection = DB_CONNECTION_STRING
        .Execute
        Set .ActiveConnection = Nothing
    End With
    add_Reaction_NotRule = True

    Exit Function
ErrorHandler:
    ErrorH 0
    Exit Function
End Function

'Verify if schedule is used in administrators
Public Function VerifyScheduleInAdmin(ByVal SchedID As Long, Optional AdminsList As Variant) As Boolean
On Error GoTo ErrorHandler

    Dim com As New adodb.Command
    Dim rs As New adodb.Recordset
    Dim i As Long

    DB_CONNECTION_STRING = getconstring()

    With com
        .CommandText = "select first_name, last_name from administrators where schedule_id=?"
        .Parameters.Append .CreateParameter("SchID", adInteger, adParamInput, , SchedID)
        .ActiveConnection = DB_CONNECTION_STRING
        rs.CursorLocation = adUseClient
        rs.Open com, , adOpenForwardOnly, adLockReadOnly
        Set .ActiveConnection = Nothing
        Set rs.ActiveConnection = Nothing
    End With
    With rs
        If .EOF Then
            VerifyScheduleInAdmin = False
            Exit Function
        End If
        VerifyScheduleInAdmin = True
        If Not IsMissing(AdminsList) Then
            Do Until .EOF
                If i >= 3 Then
                    AdminsList = AdminsList & "..."
                    Exit Do
                End If
                i = i + 1
                AdminsList = AdminsList & Trim(!first_name & "") & " " & Trim(!last_name & "") & vbCrLf
                .MoveNext
            Loop
        End If
        .Close
    End With

    Exit Function
ErrorHandler:
    ErrorH 0
    Exit Function
End Function

Public Function GetFolders(ByVal FType As enFolderType, ByVal ParentID As Long) As adodb.Recordset
On Error GoTo ErrorHandler

    Dim com As New adodb.Command
    Dim rs As New adodb.Recordset

    DB_CONNECTION_STRING = getconstring()

    With com
        .CommandText = "select * from folders where fl_type=? and parent_id=?"
        .Parameters.Append .CreateParameter("FType", adInteger, adParamInput, , FType)
        .Parameters.Append .CreateParameter("ParentID", adInteger, adParamInput, , ParentID)
        .ActiveConnection = DB_CONNECTION_STRING
        rs.CursorLocation = adUseClient
        rs.Open com, , adOpenForwardOnly, adLockReadOnly
        Set .ActiveConnection = Nothing
        Set rs.ActiveConnection = Nothing
    End With
    Set com = Nothing
    Set GetFolders = rs

    Exit Function
ErrorHandler:
    ErrorH 0
    Exit Function
End Function

Public Function CreateFolder(ByVal FType As enFolderType, ByVal ParentID As Long, ByVal FName As String) As Long
On Error GoTo ErrorHandler

    Dim com As New adodb.Command
    Dim MaxFolderID As Long

    MaxFolderID = CLng(returnmaxid("folder_id", "folders"))

    With com
        .CommandText = "insert into folders(folder_id, fl_name, parent_id, fl_type) values (?, ?, ?, ?)"
        .Parameters.Append .CreateParameter("MaxID", adInteger, adParamInput, , MaxFolderID)
        .Parameters.Append .CreateParameter("FName", adVarChar, adParamInput, 254, FName)
        .Parameters.Append .CreateParameter("ParentID", adInteger, adParamInput, , ParentID)
        .Parameters.Append .CreateParameter("FType", adInteger, adParamInput, , FType)
        .ActiveConnection = DB_CONNECTION_STRING
        .Execute
        Set .ActiveConnection = Nothing
    End With
    Set com = Nothing
    CreateFolder = MaxFolderID

    Exit Function
ErrorHandler:
    ErrorH 0
    Exit Function
End Function

Public Function GetCollectors(ByVal ParentFolderID As Long, Optional ByVal SftID As Long = 0, Optional ByVal HostID As Long = 0, Optional ByVal CompID As Long = 0) As adodb.Recordset
On Error GoTo ErrorHandler

    Dim com As New adodb.Command
    Dim rs As New adodb.Recordset

    'DB_CONNECTION_STRING = getconstring()

    With com
        If SftID > 0 Then
            .CommandText = "select * from collector where parent_collector_id is null and sft_elmnt_id=?"
            .Parameters.Append .CreateParameter("SftID", adInteger, adParamInput, , SftID)
        ElseIf HostID > 0 Then
            .CommandText = "select * from collector where parent_collector_id is null and host_id=?"
            .Parameters.Append .CreateParameter("HostID", adInteger, adParamInput, , HostID)
        ElseIf CompID > 0 Then
            .CommandText = "select * from collector where parent_collector_id is null and monitored_comps_id=?"
            .Parameters.Append .CreateParameter("CompID", adInteger, adParamInput, , CompID)
        Else
            If ParentFolderID = 0 Then
                .CommandText = "select * from collector where parent_collector_id is null and parent_folder_id is null"
            Else
                .CommandText = "select * from collector where parent_collector_id is null and parent_folder_id=?"
                .Parameters.Append .CreateParameter("ParentFolderID", adInteger, adParamInput, , ParentFolderID)
            End If
        End If
        .ActiveConnection = DB_CONNECTION_STRING
        rs.CursorLocation = adUseClient
        rs.Open com, , adOpenForwardOnly, adLockReadOnly
        Set .ActiveConnection = Nothing
        Set rs.ActiveConnection = Nothing
    End With
    Set com = Nothing
    Set GetCollectors = rs

    Exit Function
ErrorHandler:
    ErrorH 0
    Exit Function
End Function

Public Function ChangeCollectorFolder(ByVal CollectorID As Long, ByVal ParentFolderID As Long) As Boolean
On Error GoTo ErrorHandler

    Dim com As New adodb.Command
    Dim rs As New adodb.Recordset

    'DB_CONNECTION_STRING = getconstring()

    With com
        If ParentFolderID = 0 Then
            .CommandText = "update collector set parent_folder_id=null where collector_id=?"
        Else
            .CommandText = "update collector set parent_folder_id=? where collector_id=?"
            .Parameters.Append .CreateParameter("ParentFolderID", adInteger, adParamInput, , ParentFolderID)
        End If
        .Parameters.Append .CreateParameter("CollectorID", adInteger, adParamInput, , CollectorID)
        .ActiveConnection = DB_CONNECTION_STRING
        .Execute
        Set .ActiveConnection = Nothing
    End With
    Set com = Nothing
    ChangeCollectorFolder = True

    Exit Function
ErrorHandler:
    ErrorH 0
    Exit Function
End Function

Public Function ChangeAnRuleFolder(ByVal AnRuleID As Long, ByVal ParentFolderID As Long) As Boolean
On Error GoTo ErrorHandler

    Dim com As New adodb.Command
    Dim rs As New adodb.Recordset

    'DB_CONNECTION_STRING = getconstring()

    With com
        If ParentFolderID = 0 Then
            .CommandText = "update analysis_rule set parent_folder_id=null where analysis_rule_id=?"
        Else
            .CommandText = "update analysis_rule set parent_folder_id=? where analysis_rule_id=?"
            .Parameters.Append .CreateParameter("ParentFolderID", adInteger, adParamInput, , ParentFolderID)
        End If
        .Parameters.Append .CreateParameter("AnRuleID", adInteger, adParamInput, , AnRuleID)
        .ActiveConnection = DB_CONNECTION_STRING
        .Execute
        Set .ActiveConnection = Nothing
    End With
    Set com = Nothing
    ChangeAnRuleFolder = True

    Exit Function
ErrorHandler:
    ErrorH 0
    Exit Function
End Function

Public Function GetAnRules(ByVal ParentFolderID As Long) As adodb.Recordset
On Error GoTo ErrorHandler

    Dim com As New adodb.Command
    Dim rs As New adodb.Recordset

    'DB_CONNECTION_STRING = getconstring()

    With com
        If ParentFolderID = 0 Then
            .CommandText = "select * from analysis_rule where parent_folder_id is null"
        Else
            .CommandText = "select * from analysis_rule where parent_folder_id=?"
            .Parameters.Append .CreateParameter("ParentFolderID", adInteger, adParamInput, , ParentFolderID)
        End If
        .ActiveConnection = DB_CONNECTION_STRING
        rs.CursorLocation = adUseClient
        rs.Open com, , adOpenForwardOnly, adLockReadOnly
        Set .ActiveConnection = Nothing
        Set rs.ActiveConnection = Nothing
    End With
    Set com = Nothing
    Set GetAnRules = rs

    Exit Function
ErrorHandler:
    ErrorH 0
    Exit Function
End Function


Public Function RenameFolder(ByVal FolderID As Long, ByVal NewName As String) As Boolean
On Error GoTo ErrorHandler

    Dim com As New adodb.Command

    'DB_CONNECTION_STRING = getconstring()
    If FolderID = 0 Then Exit Function

    With com
        .CommandText = "update folders set fl_name=? where folder_id=?"
        .Parameters.Append .CreateParameter("NewName", adVarChar, adParamInput, 254, NewName)
        .Parameters.Append .CreateParameter("FolderID", adInteger, adParamInput, , FolderID)
        .ActiveConnection = DB_CONNECTION_STRING
        .Execute
        Set .ActiveConnection = Nothing
    End With
    RenameFolder = True

    Exit Function
ErrorHandler:
    ErrorH 0
    Exit Function
End Function

'true(-1) - ok; 1 - childs; 2 - subfolders
Public Function DeleteFolder(ByVal FType As enFolderType, ByVal FolderID As Long) As Integer
On Error GoTo ErrorHandler

    Dim com As New adodb.Command
    Dim rs As New adodb.Recordset

    'DB_CONNECTION_STRING = getconstring()
    If FolderID = 0 Then Exit Function

    With com
        If FType = ftAnRule Then
            .CommandText = "select count(1) from analysis_rule where parent_folder_id=?"
        Else
            .CommandText = "select count(1) from collector where parent_folder_id=?"
        End If
        .Parameters.Append .CreateParameter("ParentFolderID", adInteger, adParamInput, , FolderID)
        .ActiveConnection = DB_CONNECTION_STRING
        rs.CursorLocation = adUseClient
        rs.Open com, , adOpenForwardOnly, adLockReadOnly
        'Set .ActiveConnection = Nothing
        Set rs.ActiveConnection = Nothing
        If rs.Fields(0).Value > 0 Then  'There are child records
            DeleteFolder = 1
            rs.Close
            Exit Function
        End If
        rs.Close
        
        .CommandText = "select count(1) from folders where parent_id=?"
        rs.Open com, , adOpenForwardOnly, adLockReadOnly
        Set rs.ActiveConnection = Nothing
        If rs.Fields(0).Value > 0 Then  'There are subfolders
            DeleteFolder = 2
            rs.Close
            Exit Function
        End If
        rs.Close
        
        .CommandText = "delete from folders where folder_id=?"
        '.Parameters.Append .CreateParameter("FolderID", adInteger, adParamInput, , FolderID)
        '.ActiveConnection = DB_CONNECTION_STRING
        .Execute
        Set .ActiveConnection = Nothing
    End With
    DeleteFolder = True

    Exit Function
ErrorHandler:
    ErrorH 0
    Exit Function
End Function

