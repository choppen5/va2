VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsEventWzData"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Option Explicit

Private mblnFromAnRule As Boolean   'Wizard launched from an analysis rule
Private mblnNoAnRule As Boolean     'True - No Analysis rule
Private mlngAnRuleID As Long        'Analysis rule ID
Private mstrAnRuleName As String    'Analysis rule Name

Private mlngErrID As Long
Private mstrErrName As String       'Error name
Private mstrErrLevel As String      'Error Level
Private mstrEventType As String     'Event Type
Private mstrEventSubType As String  'Event SubType
Private mblnErrForSearchLog As Boolean  'Is error definition for Searching log files?
Private mstrErrSearchStr As String      'Search String
'Notification rule
Private mlngNotRuleID As Long
Private mstrNErrLevel As String         'Error Level
Private mstrNEventType As String        'Event Type
Private mstrNEventSubType As String     'Event SubType
Private mstrNotRuleName As String       'Notification Rule Name
Private mblnNotify As Boolean           'Do you want to be notified when this event occurs?
Private mblnReact As Boolean            'Do you want a reaction for this event, besides email?
Private mblnNotActive As Boolean        'Notification is active
'Reaction
Private mstrReactName As String
Private mlngReactID As Long
Private mlngReactType As Long
Private mstrReactHost As String
Private mstrReactSrv As String
Private mstrReactError As String
Private mstrReactRuleDef As String
Private mblnReactActive As Boolean
Private mstrReactName2 As String

Public Property Get ReactName2() As String
    ReactName2 = mstrReactName2
End Property

Public Property Let ReactName2(vNewValue As String)
    mstrReactName2 = vNewValue
End Property

Public Property Get NotRuleID() As Long
    NotRuleID = mlngNotRuleID
End Property

Public Property Let NotRuleID(vNewValue As Long)
    mlngNotRuleID = vNewValue
End Property

Public Property Get ErrID() As Long
    ErrID = mlngErrID
End Property

Public Property Let ErrID(vNewValue As Long)
    mlngErrID = vNewValue
End Property

Public Property Get ReactActive() As Boolean
    ReactActive = mblnReactActive
End Property

Public Property Let ReactActive(vNewValue As Boolean)
    mblnReactActive = vNewValue
End Property

Public Property Get ReactRuleDef() As String
    ReactRuleDef = mstrReactRuleDef
End Property

Public Property Let ReactRuleDef(vNewValue As String)
    mstrReactRuleDef = vNewValue
End Property

Public Property Get ReactError() As String
    ReactError = mstrReactError
End Property

Public Property Let ReactError(vNewValue As String)
    mstrReactError = vNewValue
End Property

Public Property Get ReactSrv() As String
    ReactSrv = mstrReactSrv
End Property

Public Property Let ReactSrv(vNewValue As String)
    mstrReactSrv = vNewValue
End Property

Public Property Get ReactHost() As String
    ReactHost = mstrReactHost
End Property

Public Property Let ReactHost(vNewValue As String)
    mstrReactHost = vNewValue
End Property

Public Property Get ReactType() As Long
    ReactType = mlngReactType
End Property

Public Property Let ReactType(vNewValue As Long)
    mlngReactType = vNewValue
End Property

Public Property Get ReactID() As Long
    ReactID = mlngReactID
End Property

Public Property Let ReactID(vNewValue As Long)
    mlngReactID = vNewValue
End Property

Public Property Get ReactName() As String
    ReactName = mstrReactName
End Property

Public Property Let ReactName(vNewValue As String)
    mstrReactName = vNewValue
End Property

Public Property Get NotActive() As Boolean
    NotActive = mblnNotActive
End Property

Public Property Let NotActive(vNewValue As Boolean)
    mblnNotActive = vNewValue
End Property

Public Property Get React() As Boolean
    React = mblnReact
End Property

Public Property Let React(vNewValue As Boolean)
    mblnReact = vNewValue
End Property

Public Property Get Notify() As Boolean
    Notify = mblnNotify
End Property

Public Property Let Notify(vNewValue As Boolean)
    mblnNotify = vNewValue
End Property

Public Property Get NotRuleName() As String
    NotRuleName = mstrNotRuleName
End Property

Public Property Let NotRuleName(vNewValue As String)
    mstrNotRuleName = vNewValue
End Property

Public Property Get NEventSubType() As String
    NEventSubType = mstrNEventSubType
End Property

Public Property Let NEventSubType(vNewValue As String)
    mstrNEventSubType = vNewValue
End Property

Public Property Get NEventType() As String
    NEventType = mstrNEventType
End Property

Public Property Let NEventType(vNewValue As String)
    mstrNEventType = vNewValue
End Property

Public Property Get NErrLevel() As String
    NErrLevel = mstrNErrLevel
End Property

Public Property Let NErrLevel(vNewValue As String)
    mstrNErrLevel = vNewValue
End Property


Public Property Get ErrSearchStr() As String
    ErrSearchStr = mstrErrSearchStr
End Property

Public Property Let ErrSearchStr(vNewValue As String)
    mstrErrSearchStr = vNewValue
End Property

Public Property Get ErrForSearchLog() As Boolean
    ErrForSearchLog = mblnErrForSearchLog
End Property

Public Property Let ErrForSearchLog(vNewValue As Boolean)
    mblnErrForSearchLog = vNewValue
End Property

Public Property Get EventSubType() As String
    EventSubType = mstrEventSubType
End Property

Public Property Let EventSubType(vNewValue As String)
    mstrEventSubType = vNewValue
End Property

Public Property Get EventType() As String
    EventType = mstrEventType
End Property

Public Property Let EventType(vNewValue As String)
    mstrEventType = vNewValue
End Property

Public Property Get ErrLevel() As String
    ErrLevel = mstrErrLevel
End Property

Public Property Let ErrLevel(vNewValue As String)
    mstrErrLevel = vNewValue
End Property

Public Property Get ErrName() As String
    ErrName = mstrErrName
End Property

Public Property Let ErrName(vNewValue As String)
    mstrErrName = vNewValue
End Property

Public Property Get AnRuleName() As String
    AnRuleName = mstrAnRuleName
End Property

Public Property Let AnRuleName(vNewValue As String)
    mstrAnRuleName = vNewValue
End Property

Public Property Get AnRuleID() As Long
    AnRuleID = mlngAnRuleID
End Property

Public Property Let AnRuleID(vNewValue As Long)
    mlngAnRuleID = vNewValue
End Property

Public Property Get NoAnRule() As Boolean
    NoAnRule = mblnNoAnRule
End Property

Public Property Let NoAnRule(vNewValue As Boolean)
    mblnNoAnRule = vNewValue
End Property

Public Property Get FromAnRule() As Boolean
    FromAnRule = mblnFromAnRule
End Property

Public Property Let FromAnRule(vNewValue As Boolean)
    mblnFromAnRule = vNewValue
End Property

'Save data from all the Wizard steps
Public Sub SaveAll()
On Error GoTo ErrorHandler
    Dim dobj As New VadminUI.vaDataAccess

    'Save Error Event in database
    ErrID = dobj.addsft_error_def(mstrErrName, IIf(ErrForSearchLog, ErrSearchStr, ""), _
                                    EventType, ErrLevel, EventSubType)
    If ErrID Then
        'Add Error Event to Analysis Rule
        If AnRuleID > 0 Then
            Call dobj.add_error_AnRule(AnRuleID, ErrID)
        End If

        'Add notification
        If Notify Then
            NotRuleID = dobj.addnotifcation_rule(NotRuleName, NotRuleName, "N", NEventType, NEventSubType, NErrLevel, "", BtoStr(NotActive))
            If NotRuleID = 0 Then
                MsgBox "Notification Rule has not been created.", vbExclamation
                Exit Sub
            End If

            'Add Reaction
            If React Then
                If ReactID = 0 Then
                    ReactID = dobj.add_reaction(ReactName, ReactType, dobj.padQuotes(ReactRuleDef), ReactHost, BtoStr(ReactActive), ReactSrv, ReactError)
                Else
                    ReactName = ReactName2
                End If
                Call dobj.add_Reaction_NotRule(NotRuleID, ReactID)
            End If
        End If
    End If

    Exit Sub
ErrorHandler:
    Exit Sub
End Sub



