VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsSessions"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'Class for getting sessions list for virtual listview

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
        col = "sessions_id"
    Case 2
        col = "sv_name"
    Case 3
        col = "cc_alias"
    Case 4
        col = "tk_taskid"
    Case 5
        col = "tk_pid"
    Case 6
        col = "om_login"
    Case 7
        col = "tk_hung_state"
    Case 8
        col = "tk_disp_runstate"
    Case 9
        col = "om_applet"
    Case 10
        col = "om_buscomp"
    Case 11
        col = "om_bussvc"
    Case 12
        col = "om_view"
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
        ListItem.ID = rs.Fields("sessions_id").Value & ""
    End If
End Sub

Public Function LoadValues(ByRef ListItem As SnapInLib.MMCListItem) As Boolean

    With ListItem
    If Not SetPosition(.Index) Then Exit Function
    'sessions_id sv_name cc_alias
    .Text = rs.Fields("sessions_id").Value & ""
    .ListSubItems.Add 1, , rs.Fields("sessions_id").Value & ""
    .ListSubItems.Add 2, , Trim(rs.Fields("sv_name").Value & "")
    .ListSubItems.Add 3, , Trim(rs.Fields("cc_alias").Value & "")
    .ListSubItems.Add 4, , (rs.Fields("tk_taskid").Value & "")
    .ListSubItems.Add 5, , rs.Fields("tk_pid").Value & ""
    .ListSubItems.Add 6, , Trim(rs.Fields("om_login").Value & "")
    .ListSubItems.Add 7, , rs.Fields("tk_hung_state").Value & ""
    .ListSubItems.Add 8, , Trim(rs.Fields("tk_disp_runstate").Value & "")
    .ListSubItems.Add 9, , Trim(rs.Fields("om_applet").Value & "")
    .ListSubItems.Add 10, , Trim(rs.Fields("om_buscomp").Value & "")
    .ListSubItems.Add 11, , Trim(rs.Fields("om_bussvc").Value & "")
    .ListSubItems.Add 12, , Trim(rs.Fields("om_view").Value & "")

    End With

    LoadValues = True
End Function

Public Sub Refresh()
    Dim dobj As New VadminUI.vaDataAccess

    Set rs = dobj.returndataset("select * from sessions where sft_elmnt_id = " & mSft_elmnt_id & " order by sessions_id") 'select * from errorevent order by errorevent_id")
    If rs Is Nothing Then
        mlngCount = 0
    Else
        mlngCount = rs.RecordCount
    End If
End Sub

Private Sub Class_Initialize()
'    Refresh
End Sub

Private Sub Class_Terminate()
    If Not rs.State = adStateClosed Then rs.Close
End Sub

