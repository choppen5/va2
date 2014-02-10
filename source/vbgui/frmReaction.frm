VERSION 5.00
Object = "{3B7C8863-D78F-101B-B9B5-04021C009402}#1.2#0"; "RICHTX32.OCX"
Begin VB.Form frmReaction 
   BorderStyle     =   3  'Fixed Dialog
   Caption         =   "Reaction"
   ClientHeight    =   5775
   ClientLeft      =   90
   ClientTop       =   1440
   ClientWidth     =   8355
   Icon            =   "frmReaction.frx":0000
   LinkTopic       =   "Form1"
   LockControls    =   -1  'True
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   5775
   ScaleWidth      =   8355
   ShowInTaskbar   =   0   'False
   StartUpPosition =   1  'CenterOwner
   Begin VB.CommandButton cmdOK 
      Caption         =   "OK"
      Default         =   -1  'True
      Height          =   340
      Left            =   5730
      TabIndex        =   12
      Top             =   5310
      Width           =   1180
   End
   Begin VB.CommandButton cmdCancel 
      Cancel          =   -1  'True
      Caption         =   "Cancel"
      Height          =   340
      Left            =   7035
      TabIndex        =   13
      Top             =   5310
      Width           =   1180
   End
   Begin VB.TextBox txtName 
      Height          =   285
      Left            =   1590
      MaxLength       =   20
      TabIndex        =   1
      Top             =   150
      Width           =   1815
   End
   Begin VB.CheckBox chkActive 
      Caption         =   "&Active"
      Height          =   255
      Left            =   6990
      TabIndex        =   4
      Top             =   165
      Value           =   1  'Checked
      Width           =   1215
   End
   Begin VB.ComboBox cmbType 
      Height          =   315
      ItemData        =   "frmReaction.frx":000C
      Left            =   1590
      List            =   "frmReaction.frx":0019
      Style           =   2  'Dropdown List
      TabIndex        =   6
      Top             =   660
      Width           =   1815
   End
   Begin VB.TextBox txterror 
      Height          =   495
      Left            =   150
      MultiLine       =   -1  'True
      TabIndex        =   11
      Top             =   4680
      Width           =   8055
   End
   Begin VB.ComboBox cmbhost 
      Height          =   315
      Left            =   4830
      Style           =   2  'Dropdown List
      TabIndex        =   3
      Top             =   135
      Width           =   1695
   End
   Begin VB.ComboBox cmbsv_name 
      Height          =   315
      Left            =   4830
      Style           =   2  'Dropdown List
      TabIndex        =   8
      Top             =   660
      Width           =   1695
   End
   Begin RichTextLib.RichTextBox txtrule_def 
      Height          =   3255
      Left            =   150
      TabIndex        =   9
      Top             =   1170
      Width           =   8055
      _ExtentX        =   14208
      _ExtentY        =   5741
      _Version        =   393217
      Enabled         =   -1  'True
      TextRTF         =   $"frmReaction.frx":0030
   End
   Begin VB.Label lblName 
      Caption         =   "&Name"
      Height          =   240
      Left            =   270
      TabIndex        =   0
      Top             =   172
      Width           =   975
   End
   Begin VB.Label Label1 
      Caption         =   "&Type"
      Height          =   240
      Left            =   270
      TabIndex        =   5
      Top             =   697
      Width           =   975
   End
   Begin VB.Label lblError 
      Caption         =   "&Error"
      Height          =   255
      Left            =   150
      TabIndex        =   10
      Top             =   4470
      Width           =   975
   End
   Begin VB.Label lblHost 
      Caption         =   "&Host"
      Height          =   240
      Left            =   3630
      TabIndex        =   2
      Top             =   172
      Width           =   1095
   End
   Begin VB.Label S 
      Caption         =   "&Siebel Server"
      Height          =   240
      Left            =   3630
      TabIndex        =   7
      Top             =   697
      Width           =   975
   End
End
Attribute VB_Name = "frmReaction"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
Public IsOK As Boolean

Private Sub cmdCancel_Click()
    Hide
End Sub

Private Sub cmdOK_Click()
    IsOK = True
    Hide
End Sub

Private Sub txterror_GotFocus()
    SelTextbox txterror
End Sub

Private Sub txtName_GotFocus()
    SelTextbox txtName
End Sub
