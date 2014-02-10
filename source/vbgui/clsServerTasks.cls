VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsServerTasks"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'Class for getting Server Tasks list for virtual listview

Private rs As Recordset

Private mlngCount As Long
Private mSft_elmnt_id As Long    'parent ID

Public Property Get Count() As Long
    Count = mlngCount
End Property

Public Property Let sft_elmnt_id(ByVal vNewValue As Long)
    mSft_elmnt_id = vNewValue
    Refresh
End Property

Public Sub Sort(ByVal ColumnIndex As Long, ByVal SortDesc As Boolean)

    Dim col As String
    Select Case ColumnIndex
    Case 1
        col = "tk_taskid"
    Case 2
        col = "cc_alias"
    Case 3
        col = "tk_pid"
    Case 4
        col = "cc_runmode"
    Case 5
        col = "tk_disp_runstate"
    Case 6
        col = "tk_status"
    Case 7
        col = "tk_start_time"
    Case 8
        col = "tk_end_time"
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
        ListItem.ID = rs.Fields("server_task_id").Value & ""
    End If
End Sub

Public Function LoadValues(ByRef ListItem As SnapInLib.MMCListItem) As Boolean

    With ListItem
    If Not SetPosition(.Index) Then Exit Function

    .Text = rs.Fields("tk_taskid").Value & ""
    .ListSubItems.Add 1, , rs.Fields("tk_taskid").Value & ""
    .ListSubItems.Add 2, , Trim(rs.Fields("cc_alias").Value & "")
    .ListSubItems.Add 3, , (rs.Fields("tk_pid").Value & "")
    .ListSubItems.Add 4, , Trim(rs.Fields("cc_runmode").Value & "")
    .ListSubItems.Add 5, , Trim(rs.Fields("tk_disp_runstate").Value & "")
    .ListSubItems.Add 6, , Trim(rs.Fields("tk_status").Value & "")
    .ListSubItems.Add 7, , Trim(rs.Fields("tk_start_time").Value & "")
    .ListSubItems.Add 8, , Trim(rs.Fields("tk_end_time").Value & "")

    End With

    LoadValues = True
End Function

Public Sub Refresh()
    Dim dobj As New VadminUI.vaDataAccess

    Set rs = dobj.returndataset("select * from server_task where sft_elmnt_id = " & mSft_elmnt_id & " order by server_task_id")
    If rs Is Nothing Then
        mlngCount = 0
    Else
        mlngCount = rs.RecordCount
    End If
End Sub

Private Sub Class_Terminate()
    If Not rs.State = adStateClosed Then rs.Close
End Sub


