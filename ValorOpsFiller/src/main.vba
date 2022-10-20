'' Copyright 2022 by André Vicentini (avtvicentini)

Option Explicit

#If VBA7 And Win64 Then
    Private Declare PtrSafe Sub Sleep Lib "kernel32" (ByVal dwMilliseconds As Long)
    Private Declare PtrSafe Function GetForegroundWindow Lib "user32" () As LongPtr
    Private Declare PtrSafe Function GetCurrentThreadId Lib "kernel32" () As LongPtr
    Private Declare PtrSafe Function GetWindowThreadProcessId Lib "user32" (ByVal hWnd As LongPtr, ByVal lpdwProcessId As LongPtr) As LongPtr
    Private Declare PtrSafe Function AttachThreadInput Lib "user32" (ByVal idAttach As LongPtr, ByVal idAttachTo As LongPtr, ByVal fAttach As Long) As Long
    Private Declare PtrSafe Function FindWindowByClass Lib "user32" Alias "FindWindowA" (ByVal lpClassName As String, ByVal lpWindowName As String) As LongPtr
    Private Declare PtrSafe Function FindWindow Lib "user32" Alias "FindWindowA" (ByVal lpClassName As String, ByVal lpWindowName As String) As LongPtr
    Private Declare PtrSafe Function FindWindowEx Lib "user32" Alias "FindWindowExA" (ByVal hWnd1 As LongPtr, ByVal hWnd2 As LongPtr, ByVal lpszClass As String, ByVal lpszWindow As String) As LongPtr
    Private Declare PtrSafe Function SetFocus Lib "user32" (ByVal hWnd As LongPtr) As Long
    Private Declare PtrSafe Function EnumChildWindows Lib "user32" (ByVal hWndParent As LongPtr, ByVal lpEnumFunc As LongPtr, ByVal lParam As LongPtr) As Long
    Private Declare PtrSafe Function GetClassName Lib "user32" Alias "GetClassNameA" (ByVal hWnd As LongPtr, ByVal lpClassName As String, ByVal nMaxCount As Long) As Long
    Private Declare PtrSafe Function GetWindowText Lib "user32" Alias "GetWindowTextA" (ByVal hWnd As LongPtr, ByVal lpString As String, ByVal nMaxCount As Long) As Long
#Else
    Private Declare Sub Sleep Lib "kernel32" (ByVal dwMilliseconds As Long)
    Private Declare Function GetForegroundWindow Lib "user32" () As Long
    Private Declare Function GetCurrentThreadId Lib "kernel32" () As Long
    Private Declare Function GetWindowThreadProcessId Lib "user32" (byval hWnd As long, byval lpdwProcessId As long) As long
    Private Declare Function AttachThreadInput Lib "user32" (byval idAttach As Long, byval idAttachTo As Long, byval fAttach As Long) As Long
    private Declare Function FindWindowByClass Lib "user32" Alias "FindWindowA" (ByVal lpClassName As String, ByVal lpWindowName As string) As Long
    private Declare Function FindWindow Lib "user32" Alias "FindWindowA" (ByVal lpClassName As string, ByVal lpWindowName As string) As Long
    private Declare Function FindWindowEx Lib "user32" Alias "FindWindowExA" (ByVal hWnd1 As Long, ByVal hWnd2 As Long, ByVal lpszClass As String, ByVal lpszWindow As String) As Long
    Private Declare Function SetFocus Lib "user32" (ByVal hwnd As Long) As Long
    Private Declare Function EnumChildWindows Lib "user32" (ByVal hWndParent As Long, ByVal lpEnumFunc As Long, Byval lParam As long) As Long
    Private Declare Function GetClassName Lib "user32" Alias "GetClassNameA" (ByVal hWnd As Long, ByVal lpClassName As String, ByVal nMaxCount As Long) As Long
    Private Declare Function GetWindowText Lib "user32" Alias "GetWindowTextA" (ByVal hWnd As Long, ByVal lpString As String, ByVal nMaxCount As Long) As Long
#End If

Type SearchParams
    class As String * 256
    title As String * 1024
    instance As Integer
    count As Integer
    hWnd As LongPtr
End Type

Private Const senhaDeProtecao = "sefazsp1234"

Dim hWndMain As LongPtr

Private Sub attachToWindow(ByVal hWnd As LongPtr, ByVal doAttach As Boolean)
    Dim myThread As LongPtr
    Static newThread As LongPtr
    Static curThread As LongPtr

    myThread = GetCurrentThreadId()

    If doAttach Then
        curThread = GetWindowThreadProcessId(GetForegroundWindow(), 0)
        Dim res As Long
        res = AttachThreadInput(myThread, curThread, 1)

        If hWnd <> 0 Then
            newThread = GetWindowThreadProcessId(hWnd, 0)
            res = AttachThreadInput(curThread, newThread, 1)
            res = AttachThreadInput(myThread, newThread, 1)
        End If
    Else
        If hWnd <> 0 Then
            res = AttachThreadInput(myThread, newThread, 0)
            res = AttachThreadInput(curThread, newThread, 0)
        End If

        res = AttachThreadInput(myThread, curThread, 0)
    End If

End Sub

Private Sub controlSend(ByVal hWnd As LongPtr, keys As String)
    attachToWindow hWnd, True
    
    SendKeys keys, True
    
    attachToWindow hWnd, False
End Sub

Private Sub utilAttachThreadInput(ByVal hWnd As LongPtr, doAttach As Boolean)
    
    Dim res As Long
    res = AttachThreadInput(GetCurrentThreadId(), GetWindowThreadProcessId(hWnd, 0), IIf(doAttach = True, 1, 0))

End Sub

Private Sub controlFocus(ByVal hWnd As LongPtr, class As String, ByVal instance As Integer)
    Dim child As LongPtr
    child = controlFind(hWnd, class, instance)
    If child = 0 Then
        Exit Sub
    End If
    
    utilAttachThreadInput hWndMain, True
    SetFocus child
    utilAttachThreadInput hWndMain, False
End Sub

Private Function controlFind(ByVal hWnd As LongPtr, class As String, ByVal instance As Integer) As LongPtr
    Dim params As SearchParams
    params.class = class
    params.instance = instance
    params.count = 0
    params.hWnd = 0
    EnumChildWindows hWnd, AddressOf controlFindCB, VarPtr(params)
    controlFind = params.hWnd
End Function

Private Function controlFindCB(ByVal hWnd As LongPtr, ByRef params As SearchParams) As Long
    Dim buff As String * 256
    Dim retVal As Long
    
    retVal = GetClassName(hWnd, buff, 255)
    Dim className As String
    className = Left(buff, retVal)
    If className = Trim(params.class) Then
        params.count = params.count + 1
        If params.count = params.instance Then
            params.hWnd = hWnd
            controlFindCB = 0
            Exit Function
        End If
    End If
    
    controlFindCB = 1
End Function

Private Function windowFind(ByVal hWnd As LongPtr, class As String, title As String) As LongPtr
    Dim params As SearchParams
    params.class = class
    params.title = title
    params.count = 0
    params.hWnd = 0
    EnumChildWindows hWnd, AddressOf windowFindCB, VarPtr(params)
    windowFind = params.hWnd
End Function

Private Function windowFindCB(ByVal hWnd As LongPtr, ByRef params As SearchParams) As Long
    Dim buff As String * 1024
    Dim retVal As Long
    
    retVal = GetClassName(hWnd, buff, 255)
    Dim className As String
    className = Left(buff, retVal)
    
    If className = Trim(params.class) Then
        retVal = GetWindowText(hWnd, buff, 1023)
        Dim title As String
        title = Left(buff, retVal)
        If Trim(params.title) = title Then
            params.hWnd = hWnd
            windowFindCB = 0
            Exit Function
        End If
    End If
    
    windowFindCB = 1
End Function

Private Sub controlClick(ByVal hWnd As LongPtr, class As String, ByVal instance As Integer)
    controlFocus hWnd, class, instance
    controlSend hWnd, "{ENTER}"
End Sub

Private Sub focusAndSend(ByVal hWnd As LongPtr, class As String, ByVal instance As Integer, keys As String)
    controlFocus hWnd, class, instance
    Dim key As Variant
    For Each key In Split(keys, "|")
        controlSend hWnd, CStr(key)
    Next
    Sleep 10
End Sub


Private Function getMesFromData(data As String) As Integer
    getMesFromData = CInt(Mid(data, 4, 2))
End Function

Private Function getAnoFromData(data As String) As Integer
    getAnoFromData = CInt(Mid(data, 7, 4))
End Function

Private Function formatarDecimal(dec As String) As String
    formatarDecimal = Replace(Replace(dec, "R$", ""), ".", "")
End Function

Private Function repeatString(ByVal text As String, ByVal number As Integer) As String
    repeatString = ""
    Do While (number > 0)
        repeatString = repeatString & text
        number = number - 1
    Loop
End Function

Private Function preencherMes(ByVal mes As Integer, ByVal ano As Integer, valor As String, ByVal hWnd As LongPtr)
    Dim anoAtual As Integer
    anoAtual = Year(Now())
    
    focusAndSend hWnd, "ThunderRT6ComboBox", 2, IIf(mes = 1, "{HOME}", "{HOME}" & repeatString("{DOWN}", mes - 1))
    focusAndSend hWnd, "ThunderRT6ComboBox", 1, IIf(ano = anoAtual, "{HOME}", "{HOME}" & repeatString("{DOWN}", anoAtual - ano))
    focusAndSend hWnd, "ThunderRT6TextBox", 5, valor
    controlClick hWnd, "ThunderRT6CommandButton", 4
End Function

Public Sub enviarValores()
    hWndMain = FindWindowByClass("ThunderRT6MDIForm", "Auto de Infração e Imposição de Multa - AIIM 2003")
    If hWndMain = 0 Then
        MsgBox "Janela do AIIM 2003, com a edição do auto de infração aberta, não encontrada"
        Exit Sub
    End If
    
    Dim hWnd As LongPtr
    hWnd = windowFind(hWndMain, "ThunderRT6FormDC", "Valor Total das Operações e Serviços")
    If hWnd = 0 Then
        MsgBox "Janela ""Valor Total das Operações e Serviços"" não encontrada"
        Exit Sub
    End If

    Dim i As Integer
    For i = 0 To 11
        Dim data As String
        data = Trim(Cells(4 + i, 3).Value)
        If Len(data) = 0 Then
            Exit For
        End If
        
        Dim valor As String
        valor = formatarDecimal(Cells(4 + i, 4).Value)
        
        Dim mes As Integer
        mes = getMesFromData(data)
        Dim ano As Integer
        ano = getAnoFromData(data)
        
        preencherMes mes, ano, valor, hWnd
        
        Sleep 1000
        
    Next

End Sub



