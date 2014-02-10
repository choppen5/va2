Attribute VB_Name = "modWinsock"

Option Explicit

Public Const INADDR_NONE = &HFFFF
'Public Const SOCKET_ERROR = -1
Public Const WSABASEERR = 10000
Public Const WSAEFAULT = (WSABASEERR + 14)
Public Const WSAEINVAL = (WSABASEERR + 22)
Public Const WSAEINPROGRESS = (WSABASEERR + 50)
Public Const WSAENETDOWN = (WSABASEERR + 50)
Public Const WSASYSNOTREADY = (WSABASEERR + 91)
Public Const WSAVERNOTSUPPORTED = (WSABASEERR + 92)
Public Const WSANOTINITIALISED = (WSABASEERR + 93)
Public Const WSAHOST_NOT_FOUND = 11001
Public Const WSADESCRIPTION_LEN = 257
Public Const WSASYS_STATUS_LEN = 129
Public Const WSATRY_AGAIN = 11002
Public Const WSANO_RECOVERY = 11003
Public Const WSANO_DATA = 11004


Public Type WSAData
    wVersion       As Integer
    wHighVersion   As Integer
    szDescription  As String * WSADESCRIPTION_LEN
    szSystemStatus As String * WSASYS_STATUS_LEN
    iMaxSockets    As Integer
    iMaxUdpDg      As Integer
    lpVendorInfo   As Long
End Type

Public Type HostEnt_mod
    hName     As Long
    hAliases  As Long
    hAddrType As Integer
    hLength   As Integer
    hAddrList As Long
End Type

Public Type servent
    s_name    As Long
    s_aliases As Long
    s_port    As Integer
    s_proto   As Long
End Type

Public Type protoent
    p_name    As String 'Official name of the protocol
    p_aliases As Long 'Null-terminated array of alternate names
    p_proto   As Long 'Protocol number, in host byte order
End Type

Public Declare Function WSAStartup_mod _
    Lib "ws2_32.dll" (ByVal wVR As Long, lpWSAD As WSAData) As Long

Public Declare Function WSACleanup Lib "ws2_32.dll" () As Long

Public Declare Function gethostbyaddr _
    Lib "ws2_32.dll" (addr As Long, ByVal addr_len As Long, _
                      ByVal addr_type As Long) As Long

'Public Declare Function gethostbyname
'    Lib "ws2_32.dll" (ByVal host_name As String) As Long

Public Declare Function gethostname _
    Lib "ws2_32.dll" (ByVal host_name As String, _
                      ByVal namelen As Long) As Long

Public Declare Function getservbyname _
    Lib "ws2_32.dll" (ByVal serv_name As String, _
                      ByVal proto As String) As Long

Public Declare Function getprotobynumber _
    Lib "ws2_32.dll" (ByVal proto As Long) As Long

Public Declare Function getprotobyname _
    Lib "ws2_32.dll" (ByVal proto_name As String) As Long

Public Declare Function getservbyport _
    Lib "ws2_32.dll" (ByVal Port As Integer, ByVal proto As Long) As Long

Public Declare Function inet_addr _
    Lib "ws2_32.dll" (ByVal cp As String) As Long

Public Declare Function inet_ntoa _
    Lib "ws2_32.dll" (ByVal inn As Long) As Long

'Public Declare Function htons _
'    Lib "ws2_32.dll" (ByVal hostshort As Integer) As Integer

Public Declare Function htonl _
    Lib "ws2_32.dll" (ByVal hostlong As Long) As Long

Public Declare Function ntohl _
    Lib "ws2_32.dll" (ByVal netlong As Long) As Long

Public Declare Function ntohs _
    Lib "ws2_32.dll" (ByVal netshort As Integer) As Integer

Public Declare Sub RtlMoveMemory _
    Lib "kernel32" (hpvDest As Any, _
                    ByVal hpvSource As Long, _
                    ByVal cbCopy As Long)

Public Declare Function lstrcpy _
    Lib "kernel32" Alias "lstrcpyA" (ByVal lpString1 As String, _
                                    ByVal lpString2 As Long) As Long

Public Declare Function lstrlen _
    Lib "kernel32" Alias "lstrlenA" (ByVal lpString As Any) As Long

Private Const OFFSET_4 = 4294967296#
Private Const MAXINT_4 = 2147483647
Private Const OFFSET_2 = 65536
Private Const MAXINT_2 = 32767

Public Function UnsignedToLong(value As Double) As Long
    '
    'The function takes a Double containing a value in the 
    'range of an unsigned Long and returns a Long that you 
    'can pass to an API that requires an unsigned Long
    '
    If value < 0 Or value >= OFFSET_4 Then Error 6 ' Overflow
    '
    If value <= MAXINT_4 Then
        UnsignedToLong = value
    Else
        UnsignedToLong = value - OFFSET_4
    End If
    '
End Function

Public Function LongToUnsigned(value As Long) As Double
    '
    'The function takes an unsigned Long from an API and 
    'converts it to a Double for display or arithmetic purposes
    '
    If value < 0 Then
        LongToUnsigned = value + OFFSET_4
    Else
        LongToUnsigned = value
    End If
    '
End Function

Public Function UnsignedToInteger(value As Long) As Integer
    '
    'The function takes a Long containing a value in the range 
    'of an unsigned Integer and returns an Integer that you 
    'can pass to an API that requires an unsigned Integer
    '
    If value < 0 Or value >= OFFSET_2 Then Error 6 ' Overflow
    '
    If value <= MAXINT_2 Then
        UnsignedToInteger = value
    Else
        UnsignedToInteger = value - OFFSET_2
    End If
    '
End Function

Public Function IntegerToUnsigned(value As Integer) As Long
    '
    'The function takes an unsigned Integer from and API and 
    'converts it to a Long for display or arithmetic purposes
    '
    If value < 0 Then
        IntegerToUnsigned = value + OFFSET_2
    Else
        IntegerToUnsigned = value
    End If
    '
End Function

Public Function StringFromPointer(ByVal lPointer As Long) As String
    '
    Dim strTemp As String
    Dim lRetVal As Long
    '
    'prepare the strTemp buffer
    strTemp = String$(lstrlen(ByVal lPointer), 0)
    '
    'copy the string into the strTemp buffer
    lRetVal = lstrcpy(ByVal strTemp, ByVal lPointer)
    '
    'return a string
    If lRetVal Then StringFromPointer = strTemp
    '
End Function
