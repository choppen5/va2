VERSION 5.00
Object = "{86CF1D34-0C5F-11D2-A9FC-0000F8754DA1}#2.0#0"; "MSCOMCT2.OCX"
Begin VB.Form frmWzSchedule 
   BorderStyle     =   3  'Fixed Dialog
   Caption         =   "Schedule"
   ClientHeight    =   4725
   ClientLeft      =   1080
   ClientTop       =   1440
   ClientWidth     =   4635
   Icon            =   "frmWzSchedule.frx":0000
   LinkTopic       =   "Form1"
   LockControls    =   -1  'True
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   4725
   ScaleWidth      =   4635
   ShowInTaskbar   =   0   'False
   StartUpPosition =   1  'CenterOwner
   Begin VB.CommandButton cmdCancel 
      Cancel          =   -1  'True
      Caption         =   "Cancel"
      Height          =   340
      Left            =   3330
      TabIndex        =   15
      Top             =   4290
      Width           =   1180
   End
   Begin VB.CommandButton cmdOK 
      Caption         =   "OK"
      Default         =   -1  'True
      Height          =   340
      Left            =   2025
      TabIndex        =   14
      Top             =   4290
      Width           =   1180
   End
   Begin VB.Frame frmdays 
      Caption         =   "Days"
      Height          =   3615
      Left            =   120
      TabIndex        =   1
      Top             =   540
      Width           =   1935
      Begin VB.CheckBox chkMonday 
         Caption         =   "Monday"
         Enabled         =   0   'False
         Height          =   375
         Left            =   240
         TabIndex        =   2
         Top             =   240
         Width           =   1485
      End
      Begin VB.CheckBox chkTuesday 
         Caption         =   "Tuesday"
         Enabled         =   0   'False
         Height          =   375
         Left            =   240
         TabIndex        =   3
         Top             =   720
         Width           =   1485
      End
      Begin VB.CheckBox chkWedensday 
         Caption         =   "Wedensday"
         Enabled         =   0   'False
         Height          =   375
         Left            =   240
         TabIndex        =   4
         Top             =   1200
         Width           =   1485
      End
      Begin VB.CheckBox chkThursday 
         Caption         =   "Thursday"
         Enabled         =   0   'False
         Height          =   375
         Left            =   240
         TabIndex        =   5
         Top             =   1680
         Width           =   1485
      End
      Begin VB.CheckBox chkFriday 
         Caption         =   "Friday"
         Enabled         =   0   'False
         Height          =   375
         Left            =   240
         TabIndex        =   6
         Top             =   2160
         Width           =   1485
      End
      Begin VB.CheckBox chkSaturday 
         Caption         =   "Saturday"
         Enabled         =   0   'False
         Height          =   375
         Left            =   240
         TabIndex        =   7
         Top             =   2640
         Width           =   1485
      End
      Begin VB.CheckBox chkSunday 
         Caption         =   "Sunday"
         Enabled         =   0   'False
         Height          =   375
         Left            =   240
         TabIndex        =   8
         Top             =   3120
         Width           =   1485
      End
   End
   Begin VB.CheckBox chkevery_day 
      Caption         =   "Every Day"
      Height          =   255
      Left            =   360
      TabIndex        =   0
      Top             =   150
      Value           =   1  'Checked
      Width           =   1335
   End
   Begin VB.Frame frmhours 
      Caption         =   "Hours"
      Height          =   3615
      Left            =   2220
      TabIndex        =   9
      Top             =   540
      Width           =   2295
      Begin MSComCtl2.DTPicker dtpTimeStart 
         Height          =   345
         Left            =   660
         TabIndex        =   11
         Top             =   480
         Width           =   1395
         _ExtentX        =   2461
         _ExtentY        =   609
         _Version        =   393216
         CheckBox        =   -1  'True
         CustomFormat    =   "HH:mm"
         Format          =   49741827
         UpDown          =   -1  'True
         CurrentDate     =   36494
         MinDate         =   -73411
      End
      Begin MSComCtl2.DTPicker dtpTimeEnd 
         Height          =   345
         Left            =   630
         TabIndex        =   13
         Top             =   1245
         Width           =   1515
         _ExtentX        =   2672
         _ExtentY        =   609
         _Version        =   393216
         CheckBox        =   -1  'True
         CustomFormat    =   "HH:mm"
         Format          =   49741827
         UpDown          =   -1  'True
         CurrentDate     =   36494
      End
      Begin VB.Label Label4 
         Caption         =   "End"
         Height          =   255
         Left            =   120
         TabIndex        =   12
         Top             =   1290
         Width           =   555
      End
      Begin VB.Label Label2 
         Caption         =   "Start"
         Height          =   255
         Left            =   120
         TabIndex        =   10
         Top             =   525
         Width           =   555
      End
   End
End
Attribute VB_Name = "frmWzSchedule"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
Public IsOK As Boolean

Private Sub chkevery_day_Click()
    EveryDay chkevery_day.value = 1
End Sub

Private Sub EveryDay(ByVal IsED As Boolean)
    chkMonday.Enabled = Not IsED
    chkTuesday.Enabled = Not IsED
    chkWedensday.Enabled = Not IsED
    chkThursday.Enabled = Not IsED
    chkFriday.Enabled = Not IsED
    chkSaturday.Enabled = Not IsED
    chkSunday.Enabled = Not IsED
End Sub

Private Sub cmdCancel_Click()
    Hide
End Sub

Private Sub cmdOK_Click()
    IsOK = True
    Hide
End Sub

