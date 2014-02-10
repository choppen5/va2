VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsConfigData"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Option Explicit

Private Const ServerType As String = "smtp"

Private mblnAuthentication As Boolean   '* Authentication required for SMTP
Private mstrSrvName As String           'Communication Server Name
Private mstrSMTPAddress As String       'SMTP Server address
Private mlngSMTPPort As Long            '* SMTP Server Port
Private mlngSrvID As Long               'Server ID
Private mstrSMTPuser As String
Private mstrSMTPpassword As String

Private mstrAdminFName As String        'Administrator's First Name
Private mstrAdminLName As String        'Administrator's Last Name
Private mstrAdminEmail As String        'Administrator's email
Private mlngAdminID As Long             'Administrator's ID in DB
Private mstrAdminFullName As String

Private mstrSchName As String           'Schedule's Name
Private mblnSch7x24 As Boolean          'All the Time
Private mbytSchDayOfWeek As Byte        'Bitmap of the days
Private mdtmSchTimeStart As Variant     'Start Time
Private mdtmSchTimeEnd As Variant       'End Time
Private mlngSchID As Long               'Schedule's ID
Private mblnSchOK As Boolean            'Schedule OK

Private mblnAddedAdmin As Boolean
Private mblnAddedSchedule As Boolean

Public Property Get AddedAdmin() As Boolean
    AddedAdmin = mblnAddedAdmin
End Property

Public Property Get AddedSchedule() As Boolean
    AddedSchedule = mblnAddedSchedule
End Property

Public Property Get SMTPpassword() As String
    SMTPpassword = mstrSMTPpassword
End Property

Public Property Let SMTPpassword(vNewValue As String)
    mstrSMTPpassword = vNewValue
End Property

Public Property Get SMTPuser() As String
    SMTPuser = mstrSMTPuser
End Property

Public Property Let SMTPuser(vNewValue As String)
    mstrSMTPuser = vNewValue
End Property

Public Property Get ScheduleOk() As Boolean
    ScheduleOk = mblnSchOK
End Property

Public Property Get AdminOK() As Boolean
    AdminOK = AdminID <> 0
End Property

Public Property Get SrvOK() As Boolean
    SrvOK = SrvID <> 0
End Property

Public Property Get SrvID() As Long
    SrvID = mlngSrvID
End Property

Public Property Let SrvID(vNewValue As Long)
    mlngSrvID = vNewValue
End Property

Public Property Get SchID() As Long
    SchID = mlngSchID
End Property

Public Property Let SchID(vNewValue As Long)
    mlngSchID = vNewValue
End Property

Public Property Get SchTimeEnd() As Variant
    SchTimeEnd = mdtmSchTimeEnd
End Property

Public Property Let SchTimeEnd(vNewValue As Variant)
    mdtmSchTimeEnd = vNewValue
End Property

Public Property Get SchTimeStart() As Variant
    SchTimeStart = mdtmSchTimeStart
End Property

Public Property Let SchTimeStart(vNewValue As Variant)
    mdtmSchTimeStart = vNewValue
End Property

Public Property Get SchDayOfWeek() As Byte
    SchDayOfWeek = mbytSchDayOfWeek
End Property

Public Property Let SchDayOfWeek(vNewValue As Byte)
    mbytSchDayOfWeek = vNewValue
End Property

Public Property Get Sch7x24() As Boolean
    Sch7x24 = mblnSch7x24
End Property

Public Property Let Sch7x24(vNewValue As Boolean)
    mblnSch7x24 = vNewValue
End Property

Public Property Get SchName() As String
    SchName = mstrSchName
End Property

Public Property Let SchName(vNewValue As String)
    mstrSchName = vNewValue
End Property

Public Property Get AdminFullName() As String
    AdminFullName = mstrAdminFullName
End Property

Public Property Let AdminFullName(vNewValue As String)
    mstrAdminFullName = vNewValue
End Property

Public Property Get AdminID() As Long
    AdminID = mlngAdminID
End Property

Public Property Let AdminID(vNewValue As Long)
    mlngAdminID = vNewValue
End Property

Public Property Get AdminEmail() As String
    AdminEmail = mstrAdminEmail
End Property

Public Property Let AdminEmail(vNewValue As String)
    mstrAdminEmail = vNewValue
End Property

Public Property Get AdminLName() As String
    AdminLName = mstrAdminLName
End Property

Public Property Let AdminLName(vNewValue As String)
    mstrAdminLName = vNewValue
End Property

Public Property Get AdminFName() As String
    AdminFName = mstrAdminFName
End Property

Public Property Let AdminFName(vNewValue As String)
    mstrAdminFName = vNewValue
End Property

Public Property Get SMTPPort() As Long
    SMTPPort = mlngSMTPPort
End Property

Public Property Let SMTPPort(vNewValue As Long)
    mlngSMTPPort = vNewValue
End Property

Public Property Get SMTPAddress() As String
    SMTPAddress = mstrSMTPAddress
End Property

Public Property Let SMTPAddress(vNewValue As String)
    mstrSMTPAddress = vNewValue
End Property

Public Property Get SrvName() As String
    SrvName = mstrSrvName
End Property

Public Property Let SrvName(vNewValue As String)
    mstrSrvName = vNewValue
End Property

Public Property Get Authentication() As Boolean
    Authentication = mblnAuthentication
End Property

Public Property Let Authentication(vNewValue As Boolean)
    mblnAuthentication = vNewValue
End Property

Private Sub Class_Initialize()
    mblnAuthentication = True
End Sub

'Save data from all Wizard steps
Public Sub SaveAll()
On Error GoTo ErrorHandler
    Dim dobj As New VadminUI.vaDataAccess

    'Save Communication server in database
    SrvID = dobj.add_comunicationserver(SrvName, SMTPAddress, ServerType, SMTPPort)

    If SrvOK Then

        'Add server vals
        Call dobj.add_com_srvr_vals("smtp_port", SMTPPort, SrvID)
        If Authentication Then
            Call dobj.add_com_srvr_vals("smtp_authentication", "TRUE", SrvID)
            Call dobj.add_com_srvr_vals("smtp_user", SMTPuser, SrvID)
            Call dobj.add_com_srvr_vals("smtp_password", SMTPpassword, SrvID)
        End If

        'Save New Admin in database
        If AdminID = 0 Then
            AdminID = dobj.add_administrators(AdminFName, AdminLName, AdminEmail, "", "")
            mblnAddedAdmin = AdminID > 0
        End If

        If AdminOK Then
            'Add server to admin
            dobj.add_com_admin_link AdminID, SrvID

            'Save New Schedule
            If SchID = 0 Then
                SchID = dobj.add_schedule(SchName, BtoStr(Sch7x24), BtoStr(SchDayOfWeek And SchEvery), _
                                        BtoStr(SchDayOfWeek And SchMonday), _
                                        BtoStr(SchDayOfWeek And SchTuesday), _
                                        BtoStr(SchDayOfWeek And SchWedensday), _
                                        BtoStr(SchDayOfWeek And SchThursday), _
                                        BtoStr(SchDayOfWeek And SchFriday), _
                                        BtoStr(SchDayOfWeek And SchSaturday), _
                                        BtoStr(SchDayOfWeek And SchSunday), _
                                        Format(mdtmSchTimeStart, "Hh"), Format(mdtmSchTimeStart, "Nn"), _
                                        Format(mdtmSchTimeEnd, "Hh"), Format(mdtmSchTimeEnd, "Nn"))
                mblnAddedSchedule = SchID > 0
            End If
            mblnSchOK = SchID > 0
            'Add admin to schedule
            If ScheduleOk Then
                mblnSchOK = dobj.add_admin_schedule(AdminID, SchID)
            End If
        End If

    End If

    Exit Sub
ErrorHandler:
    Exit Sub
End Sub

