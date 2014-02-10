Attribute VB_Name = "Registry"
'*******************************************************************************
' Module:   Registry
' Author:   Tony Priest, Dart Communications
' Date:     9/13/99
'
' Purpose:  Allows Reading and Writing to Keys under the
'           Local Machine Hive in the Registry
'*******************************************************************************
Option Explicit

Public Type SECURITY_ATTRIBUTES
    nLength As Long
    lpSecurityDescriptor As Long
    bInheritHandle As Long
End Type

Public Const HKEY_LOCAL_MACHINE = &H80000002
Public Const HKEY_CURRENT_USER = &H80000001
Public Const READ_CONTROL = &H20000
Public Const STANDARD_RIGHTS_ALL = &H1F0000
Public Const STANDARD_RIGHTS_READ = (READ_CONTROL)
Public Const STANDARD_RIGHTS_EXECUTE = (READ_CONTROL)
Public Const STANDARD_RIGHTS_REQUIRED = &HF0000
Public Const STANDARD_RIGHTS_WRITE = (READ_CONTROL)
Public Const SYNCHRONIZE = &H100000
Public Const REG_SZ = 1                         ' Unicode nul terminated string
Public Const KEY_SET_VALUE = &H2
Public Const KEY_QUERY_VALUE = &H1
Public Const KEY_CREATE_LINK = &H20
Public Const KEY_CREATE_SUB_KEY = &H4
Public Const KEY_ENUMERATE_SUB_KEYS = &H8
Public Const KEY_EVENT = &H1     '  Event contains key event record
Public Const KEY_NOTIFY = &H10
Public Const KEY_READ = ((STANDARD_RIGHTS_READ Or KEY_QUERY_VALUE Or KEY_ENUMERATE_SUB_KEYS Or KEY_NOTIFY) And (Not SYNCHRONIZE))
Public Const KEY_EXECUTE = ((KEY_READ) And (Not SYNCHRONIZE))
Public Const KEY_ALL_ACCESS = ((STANDARD_RIGHTS_ALL Or KEY_QUERY_VALUE Or KEY_SET_VALUE Or KEY_CREATE_SUB_KEY Or KEY_ENUMERATE_SUB_KEYS Or KEY_NOTIFY Or KEY_CREATE_LINK) And (Not SYNCHRONIZE))

Private Declare Function RegOpenKeyEx Lib "advapi32.dll" Alias "RegOpenKeyExA" (ByVal hKey As Long, ByVal lpSubKey As String, ByVal ulOptions As Long, ByVal samDesired As Long, phkResult As Long) As Long
Private Declare Function RegQueryValueEx Lib "advapi32.dll" Alias "RegQueryValueExA" (ByVal hKey As Long, ByVal lpValueName As String, ByVal lpReserved As Long, lpType As Long, lpData As Any, lpcbData As Long) As Long         ' Note that if you declare the lpData parameter as String, you must pass it By Value.
Private Declare Function RegCloseKey Lib "advapi32.dll" (ByVal hKey As Long) As Long
Private Declare Function RegCreateKeyEx Lib "advapi32.dll" Alias "RegCreateKeyExA" (ByVal hKey As Long, ByVal lpSubKey As String, ByVal Reserved As Long, ByVal lpClass As String, ByVal dwOptions As Long, ByVal samDesired As Long, lpSecurityAttributes As SECURITY_ATTRIBUTES, phkResult As Long, lpdwDisposition As Long) As Long
Private Declare Function RegSetValueEx Lib "advapi32.dll" Alias "RegSetValueExA" (ByVal hKey As Long, ByVal lpValueName As String, ByVal Reserved As Long, ByVal dwType As Long, lpData As Any, ByVal cbData As Long) As Long         ' Note that if you declare the lpData parameter as String, you must pass it By Value.

Public Sub SaveRegSetting(rootkey As Long, key As String, value As String, Data As String)
    Dim success As Long
    Dim hKey As Long
    Dim disp As Long
    Dim secAttr As SECURITY_ATTRIBUTES
    Dim S As String
    
    success = RegCreateKeyEx(rootkey, key, 0, "", 0, KEY_ALL_ACCESS, secAttr, hKey, disp)
    If success = 0 Then
        RegSetValueEx hKey, value, 0&, REG_SZ, ByVal Data, Len(Data)
        RegCloseKey hKey
    End If
End Sub

Public Function GetRegSetting(ByVal rootkey As Long, ByVal key As String, ByVal value As String, ByVal default As String) As String
    Dim success As Long
    Dim regData As String
    Dim hKey As Long
    Dim regDataLength As Long
    
    ' Assign default return value
    GetRegSetting = default
    ' Try to open key
    success = RegOpenKeyEx(rootkey, key, 0&, KEY_ALL_ACCESS, hKey)
    If success <> 0 Then Exit Function
    
    ' Get length needed
    success = RegQueryValueEx(hKey, value, 0&, vbNull, vbNull, regDataLength)
    If regDataLength = 0 Then Exit Function
    
    ' Get value
    regData = String(regDataLength - 1, 0)
    success = RegQueryValueEx(hKey, value, 0&, vbNull, ByVal regData, regDataLength)

    If success = 0 Then GetRegSetting = regData
    RegCloseKey hKey
End Function
