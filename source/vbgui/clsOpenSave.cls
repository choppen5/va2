VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsOpenSave"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Attribute VB_Ext_KEY = "SavedWithClassBuilder" ,"Yes"
Attribute VB_Ext_KEY = "Top_Level" ,"Yes"
Option Explicit

Private Declare Function GetOpenFileName Lib "comdlg32.dll" Alias "GetOpenFileNameA" (pOpenfilename As OPENFILENAME) As Long
Private Declare Function GetSaveFileName Lib "comdlg32.dll" Alias "GetSaveFileNameA" (pOpenfilename As OPENFILENAME) As Long

Private Const cdlAPIcancel = 32755

Private Type OPENFILENAME
  lStructSize As Long
  hwndOwner As Long
  hInstance As Long
  lpstrFilter As String
  lpstrCustomFilter As String
  nMaxCustFilter As Long
  nFilterIndex As Long
  lpstrFile As String
  nMaxFile As Long
  lpstrFileTitle As String
  nMaxFileTitle As Long
  lpstrInitialDir As String
  lpstrTitle As String
  flags As Long
  nFileOffset As Integer
  nFileExtension As Integer
  lpstrDefExt As String
  lCustData As Long
  lpfnHook As Long
  lpTemplateName As String
End Type

'  OFN_SHAREWARN = &H0
'  OFN_SHARENOWARN = &H1
'  OFN_SHAREFALLTHROUGH = &H2
Public Enum OFN_Flags
  OFN_READONLY = &H1
  OFN_OVERWRITEPROMPT = &H2
  OFN_HIDEREADONLY = &H4
  OFN_NOCHANGEDIR = &H8
  OFN_SHOWHELP = &H10
  OFN_ENABLEHOOK = &H20
  OFN_ENABLETEMPLATE = &H40
  OFN_ENABLETEMPLATEHANDLE = &H80
  OFS_MAXPATHNAME = &H80
  OFN_NOVALIDATE = &H100
  OFN_ALLOWMULTISELECT = &H200
  OFN_EXTENSIONDIFFERENT = &H400
  OFN_PATHMUSTEXIST = &H800
  OFN_FILEMUSTEXIST = &H1000
  OFN_CREATEPROMPT = &H2000
  OFN_SHAREAWARE = &H4000
  OFN_NOREADONLYRETURN = &H8000
  OFN_NOTESTFILECREATE = &H10000
  OFN_NONETWORKBUTTON = &H20000
  OFN_NOLONGNAMES = &H40000
  OFN_EXPLORER = &H80000
  OFN_NODEREFERENCELINKS = &H100000
  OFN_LONGNAMES = &H200000
End Enum

'local variable(s) to hold property value(s)
Private mvarCancelError As Boolean 'local copy
Private mvarDefaultExt As String 'local copy
Private mvarDialogTitle As String 'local copy
Private mvarFileName As String 'local copy
Private mvarFileTitle As String 'local copy
Private mvarFilterIndex As Integer 'local copy
Private mvarFilter As String 'local copy
Private mvarFlags As Long 'local copy
Private mvarInitDir As String 'local copy
Private mvarMaxFileSize As Integer 'local copy
Private mvarhWnd As Long 'local copy
Private mvarFileExt As Integer 'local copy
Public Property Let FileExt(ByVal vData As Integer)
'used when assigning a value to the property, on the left side of an assignment.
'Syntax: X.FileExt = 5
mvarFileExt = vData
End Property

Public Property Get FileExt() As Integer
'used when retrieving value of a property, on the right side of an assignment.
'Syntax: Debug.Print X.FileExt
FileExt = mvarFileExt
End Property

Public Property Let hWnd(ByVal vData As Long)
' The owner of the window
' Default: 0
mvarhWnd = vData
End Property

Public Property Get hWnd() As Long
hWnd = mvarhWnd
End Property

Public Sub ShowSave()
Dim ofn As OPENFILENAME
Dim retval As Long

With ofn
  .flags = flags
  .hwndOwner = hWnd
  .hInstance = 0
  .lCustData = 0
  .lpfnHook = 0
'  .lpstrCustomFilter = vbNullChar  'Removed for NT compatibility problems
  .lpstrDefExt = DefaultExt
  .lpstrFile = FileName & String$(MaxFileSize - Len(FileName) + 1, vbNullChar)
  .lpstrFileTitle = FileTitle & Space$(256)
  .lpstrFilter = mvarFilter
  .lpstrInitialDir = InitDir
  .lpstrTitle = DialogTitle
  .lpTemplateName = 0
  .lStructSize = Len(ofn)
  .nFileExtension = 0
  .nFileOffset = 0
  .nFilterIndex = FilterIndex
  .nMaxCustFilter = 0
  .nMaxFile = MaxFileSize
  .nMaxFileTitle = 260
End With

retval = GetSaveFileName(ofn)

If retval > 0 Then
  With ofn
    flags = .flags
    DefaultExt = .lpstrDefExt
    FileName = Trim$(.lpstrFile)
    FileTitle = Trim$(.lpstrFileTitle)
    FileExt = .nFileExtension
    mvarFilter = Trim$(.lpstrFilter)
    InitDir = Trim$(.lpstrInitialDir)
    FilterIndex = Trim$(.nFilterIndex)
  End With
Else
  If CancelError Then Err.Raise cdlAPIcancel, "Run-time error", "Cancel was selected"
End If
End Sub

Public Sub ShowOpen()
Dim ofn As OPENFILENAME
Dim retval As Long

With ofn
  .flags = flags
  .hwndOwner = hWnd
  .hInstance = 0
  .lCustData = 0
  .lpfnHook = 0
'  .lpstrCustomFilter = vbNullChar  ' Removed for NT compatibility problem
  .lpstrDefExt = DefaultExt
  .lpstrFile = FileName & String$(MaxFileSize - Len(FileName) + 1, 0)
  .lpstrFileTitle = FileTitle & Space$(256)
  .lpstrFilter = mvarFilter
  .lpstrInitialDir = InitDir
  .lpstrTitle = DialogTitle
  .lpTemplateName = 0
  .lStructSize = Len(ofn)
  .nFileExtension = 0
  .nFileOffset = 0
  .nFilterIndex = FilterIndex
  .nMaxCustFilter = 0
  .nMaxFile = MaxFileSize
  .nMaxFileTitle = 260
End With

retval = GetOpenFileName(ofn)

If retval > 0 Then
  With ofn
    flags = .flags
    DefaultExt = .lpstrDefExt
    FileName = Trim$(.lpstrFile)
    FileTitle = Trim$(.lpstrFileTitle)
    FileExt = .nFileExtension
    mvarFilter = Trim$(.lpstrFilter)
    InitDir = Trim$(.lpstrInitialDir)
    FilterIndex = Trim$(.nFilterIndex)
  End With
Else
'  If CancelError Then Err.Raise 1, "Run-time error", "Cancel was selected"
End If
End Sub

Public Property Let MaxFileSize(ByVal vData As Integer)
' The maximum length of file name returned
' Default: 260
mvarMaxFileSize = vData
End Property

Public Property Get MaxFileSize() As Integer
MaxFileSize = mvarMaxFileSize
End Property

Public Property Let InitDir(ByVal vData As String)
' Directory to open window in
' Default: "C:\"
mvarInitDir = vData
End Property

Public Property Get InitDir() As String
InitDir = mvarInitDir
End Property

Public Property Let flags(ByVal vData As OFN_Flags)
' Flags specifying properties of dialog box
' Default: 0
mvarFlags = vData
End Property

Public Property Get flags() As OFN_Flags
flags = mvarFlags
End Property

Public Property Let Filter(ByVal vData As String)
' Filters that the user can select in drowpdown combo
' Usage: Friendlyname1|*.ex1|Freindlyname2|*.ex2 etc.
' Default: "All Files (*.*)|*.*"

Dim pipepos As String

Do While InStr(vData, "|") > 0
  pipepos = InStr(vData, "|")

  If pipepos > 0 Then
    vData = Left$(vData, pipepos - 1) & vbNullChar & Right$(vData, Len(vData) - pipepos)
  End If

Loop

If Right$(vData, 2) <> vbNullChar & vbNullChar Then vData = vData & vbNullChar
If Right$(vData, 2) <> vbNullChar & vbNullChar Then vData = vData & vbNullChar

mvarFilter = vData
End Property

Public Property Get Filter() As String
Dim nullpos As String
Dim tempfilter As String

tempfilter = mvarFilter

Do While InStr(tempfilter, vbNullChar) > 0
  nullpos = InStr(tempfilter, vbNullChar)

  If nullpos > 0 Then
    tempfilter = Left$(tempfilter, nullpos - 1) & vbNullChar & Right$(tempfilter, Len(tempfilter) - nullpos)
  End If

Loop

If Right$(tempfilter, 1) = "|" Then tempfilter = Left$(tempfilter, Len(tempfilter) - 1)
If Right$(tempfilter, 1) = "|" Then tempfilter = Left$(tempfilter, Len(tempfilter) - 1)

Filter = tempfilter
End Property

Public Property Let FilterIndex(ByVal vData As Integer)
' Index of filter to select as default
' The first item is 1, second 2, etc.
' Default: 1
mvarFilterIndex = vData
End Property

Public Property Get FilterIndex() As Integer
FilterIndex = mvarFilterIndex
End Property

Public Property Let FileTitle(ByVal vData As String)
' The name of the file without path
mvarFileTitle = vData
End Property

Public Property Get FileTitle() As String
FileTitle = mvarFileTitle
End Property

Public Property Let FileName(ByVal vData As String)
' Name of the file, including path
mvarFileName = vData
End Property

Public Property Get FileName() As String
FileName = mvarFileName
End Property

Public Property Let DialogTitle(ByVal vData As String)
' The name of the dialog box
mvarDialogTitle = vData
End Property

Public Property Get DialogTitle() As String
DialogTitle = mvarDialogTitle
End Property

Public Property Let DefaultExt(ByVal vData As String)
' The default extension added if one is not specified in the name
mvarDefaultExt = vData
End Property

Public Property Get DefaultExt() As String
DefaultExt = mvarDefaultExt
End Property

Public Property Let CancelError(ByVal vData As Boolean)
' Raise an error if user clicks cancel
' Default: False
mvarCancelError = vData
End Property

Public Property Get CancelError() As Boolean
CancelError = mvarCancelError
End Property

Private Sub Class_Initialize()
CancelError = False
DefaultExt = ""
DialogTitle = ""
FileName = ""
FileTitle = ""
Filter = "All Files (*.*)|*.*"
FilterIndex = 1
flags = 0
InitDir = "C:\"
MaxFileSize = 260
hWnd = 0
End Sub
