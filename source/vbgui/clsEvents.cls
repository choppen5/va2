VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsEvents"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'Class for getting events list for virtual listview

Private rs As Recordset

Private mlngCount As Long

Public Property Get Count() As Long
    Count = mlngCount
End Property

Public Sub Sort(ByVal ColumnIndex As Long, ByVal SortDesc As Boolean)

    Dim col As String
    Select Case ColumnIndex
    Case 1
        col = "errorevent_id"
    Case 2
        col = "type"
    Case 3
        col = "event_sub_type"
    Case 4
        col = "event_level"
    Case 5
        col = "event_time"
    Case 6
        col = "event_string"
    Case 7
        col = "error_defs_id"
    Case 8
        col = "cc_alias"
    Case 9
        col = "sv_name"
    Case 10
        col = "sft_elmnt_id"
    Case 11
        col = "processed"
    Case 12
        col = "host"
    Case 13
        col = "file_path"
    Case Else
        Exit Sub
    End Select
    
    rs.Sort = col & IIf(SortDesc, " DESC", "")
    Debug.Print "Sort: " & rs.Sort & " | Count: " & rs.RecordCount
End Sub

Private Function SetPosition(ByVal Index As Long) As Boolean
    Dim Diff As Long

'Debug.Print Format(Index, "@@@@")
    If Index > Count Or Index <= 0 Then Exit Function

    Diff = Index - rs.AbsolutePosition
    If Diff = 0 Then
    Else
        If Index = 1 Then
            rs.MoveFirst
        ElseIf Index = Count Then
            rs.MoveLast
        Else
            rs.Move Diff
        End If
    End If

    SetPosition = True

End Function

Public Sub SetListItemID(ByRef ListItem As SnapInLib.MMCListItem)
    If SetPosition(ListItem.Index) Then
        ListItem.ID = rs.Fields("errorevent_id").Value & ""
    End If
End Sub

Public Function LoadValues(ByRef ListItem As SnapInLib.MMCListItem) As Boolean

    With ListItem
    If Not SetPosition(.Index) Then Exit Function
    
    .Text = rs.Fields("errorevent_id").Value & ""
    .ListSubItems.Add 1, , rs.Fields("errorevent_id").Value & ""
    .ListSubItems.Add 2, , Trim(rs.Fields("type").Value & "")
    .ListSubItems.Add 3, , Trim(rs.Fields("event_sub_type").Value & "")
    .ListSubItems.Add 4, , Trim(rs.Fields("event_level").Value & "")
    .ListSubItems.Add 5, , rs.Fields("event_time").Value & ""
    .ListSubItems.Add 6, , Trim(rs.Fields("event_string").Value & "")
    .ListSubItems.Add 7, , rs.Fields("error_defs_id").Value & ""
    .ListSubItems.Add 8, , Trim(rs.Fields("cc_alias").Value & "")
    .ListSubItems.Add 9, , Trim(rs.Fields("sv_name").Value & "")
    .ListSubItems.Add 10, , rs.Fields("sft_elmnt_id").Value & ""
    .ListSubItems.Add 11, , rs.Fields("processed").Value & ""
    .ListSubItems.Add 12, , Trim(rs.Fields("host").Value & "")
    .ListSubItems.Add 13, , Trim(rs.Fields("file_path").Value & "")

    End With

    LoadValues = True
End Function

Public Sub Refresh()
    Dim dobj As New VadminUI.vaDataAccess

    Set rs = dobj.returndataset("select * from errorevent order by errorevent_id")
    If rs Is Nothing Then
        mlngCount = 0
    Else
        mlngCount = rs.RecordCount
    End If
End Sub

Private Sub Class_Initialize()
    Refresh
End Sub

Private Sub Class_Terminate()
    If Not rs.State = adStateClosed Then rs.Close
End Sub
