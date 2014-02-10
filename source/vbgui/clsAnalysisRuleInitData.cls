VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsAnalysisRuleInitData"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Option Explicit

Public InitString As String

Public Event OpenEventWizard()
Private mlngAnalysisRuleID As Long
Private mstrAnalysisRuleName As String

Public Property Get AnalysisRuleName() As String
    AnalysisRuleName = mstrAnalysisRuleName
End Property

Public Property Get AnalysisRuleID() As Long
    AnalysisRuleID = mlngAnalysisRuleID
End Property

Public Sub OpenEventWizard(ByVal pAnalysisRuleID As Long, ByVal pAnalysisRuleName As String)
    mlngAnalysisRuleID = pAnalysisRuleID
    mstrAnalysisRuleName = pAnalysisRuleName
    RaiseEvent OpenEventWizard
End Sub
