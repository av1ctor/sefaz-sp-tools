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
    Private Declare PtrSafe Function EnumWindows Lib "user32" (ByVal lpEnumFunc As LongPtr, ByVal lParam As LongPtr) As Long
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
    Private Declare Function EnumWindows Lib "user32" (ByVal lpEnumFunc As Long, ByVal lParam As Long) As Long
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

Private hWndMain As LongPtr

Private Sub attachToWindow( _
    ByVal hWnd As LongPtr, _
    ByVal doAttach As Boolean _
)
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

Private Sub controlSend( _
    ByVal hWnd As LongPtr, _
    keys As String _
)
    attachToWindow hWnd, True
    
    SendKeys keys, True
    
    attachToWindow hWnd, False
End Sub

Private Sub utilAttachThreadInput( _
    ByVal hWnd As LongPtr, _
    doAttach As Boolean _
)
    
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

Private Function controlFind( _
    ByVal hWnd As LongPtr, _
    class As String, _
    ByVal instance As Integer _
) As LongPtr
    Dim params As SearchParams
    params.class = class
    params.instance = instance
    params.count = 0
    params.hWnd = 0
    If hWnd <> 0 Then
        EnumChildWindows hWnd, AddressOf controlFindCB, VarPtr(params)
    Else
        EnumWindows AddressOf controlFindCB, VarPtr(params)
    End If
    controlFind = params.hWnd
End Function

Private Function controlFindCB( _
    ByVal hWnd As LongPtr, _
    ByRef params As SearchParams _
) As Long
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

Private Function windowFind( _
    ByVal hWnd As LongPtr, _
    class As String, _
    title As String _
) As LongPtr
    Dim params As SearchParams
    params.class = class
    params.title = title
    params.count = 0
    params.hWnd = 0
    If hWnd <> 0 Then
        EnumChildWindows hWnd, AddressOf windowFindCB, VarPtr(params)
    Else
        EnumWindows AddressOf windowFindCB, VarPtr(params)
    End If
    windowFind = params.hWnd
End Function

Private Function windowFindWaiting( _
    ByVal hWnd As LongPtr, _
    class As String, _
    title As String, _
    ByVal seconds As Integer _
) As LongPtr
    Dim elapsed As Integer
    elapsed = 0
    
    Do While elapsed < seconds * 10
        Dim child As LongPtr
        child = windowFind(hWnd, class, title)
        If child <> 0 Then
            windowFindWaiting = child
            Exit Function
        End If
        Sleep 100
        elapsed = elapsed + 10
    Loop
    
    windowFindWaiting = 0
    
End Function

Private Function windowFindCB( _
    ByVal hWnd As LongPtr, _
    ByRef params As SearchParams _
) As Long
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

Private Sub controlClick( _
    ByVal hWnd As LongPtr, _
    class As String, _
    ByVal instance As Integer _
)
    controlFocus hWnd, class, instance
    controlSend hWnd, "{ENTER}"
End Sub

Private Sub listClickFirstRow( _
    ByVal hWnd As LongPtr, _
    class As String, _
    ByVal instance As Integer _
)
    controlFocus hWnd, class, instance
    controlSend hWnd, "{HOME}"
End Sub

Private Sub focusAndSend( _
    ByVal hWnd As LongPtr, _
    class As String, _
    ByVal instance As Integer, _
    keys As String _
)
    controlFocus hWnd, class, instance
    Dim key As Variant
    For Each key In Split(keys, "|")
        controlSend hWnd, CStr(key)
    Next
    Sleep 10
End Sub

Private Sub waitDialogAndClick( _
    hWnd As LongPtr, _
    class As String, _
    title As String, _
    buttonClass As String, _
    ByVal buttonInstance As Integer, _
    ByVal seconds As Integer _
)
    Dim hWndDlg As LongPtr
    hWndDlg = windowFindWaiting(hWnd, class, title, seconds)
    If hWndDlg = 0 Then
        Exit Sub
    End If

    controlClick hWndDlg, buttonClass, buttonInstance
End Sub

Private Function getMesFromData(data As String) As Integer
    getMesFromData = CInt(Mid(data, 4, 2))
End Function

Private Function getAnoFromData(data As String) As Integer
    getAnoFromData = CInt(Mid(data, 7, 4))
End Function

Private Function dateDaysInMonth(ByVal ano As String, ByVal mes As String) As Integer
    Dim data As Date
    data = CDate("01/" & mes & "/" & ano)

    dateDaysInMonth = Day(DateSerial(year(data), month(data) + 1, 1) - 1)
End Function

Private Function formatarData(data As String) As String
    If Len(data) = 7 Then
        Dim month As String
        month = Right(data, 2)
        Dim year As String
        year = Left(data, 4)
        Dim days As Integer
        days = dateDaysInMonth(year, month)
        formatarData = days & "/" & month & "/" & Right(year, 2)
    Else
        formatarData = Left(data, 6) & Right(data, 2)
    End If
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

Private Sub preencherTributo(ByVal hWnd As LongPtr, valor As String)
    focusAndSend hWnd, "ThunderRT6TextBox", 13, formatarDecimal(valor)
End Sub

Private Sub preencherDci(ByVal hWnd As LongPtr, valor As String)
    focusAndSend hWnd, "MSMaskWndClass", 2, formatarData(valor)
End Sub

Private Sub preencherDij(ByVal hWnd As LongPtr, valor As String, checkDlg As Boolean)
    focusAndSend hWnd, "MSMaskWndClass", 3, formatarData(valor) & "{TAB}"
    If checkDlg Then
        waitDialogAndClick 0, "#32770", "AIIM2003", "Button", 1, 3
    End If
End Sub

Private Sub preencherDcm(ByVal hWnd As LongPtr, valor As String)
    focusAndSend hWnd, "MSMaskWndClass", 1, formatarData(valor)
End Sub

Private Sub preencherBasico(ByVal hWnd As LongPtr, valor As String)
    focusAndSend hWnd, "ThunderRT6TextBox", 14, formatarDecimal(valor)
End Sub

Private Sub preencherDavb(ByVal hWnd As LongPtr, valor As String)
    focusAndSend hWnd, "MSMaskWndClass", 4, formatarData(valor)
End Sub

Private Sub preencherDfg(ByVal hWnd As LongPtr, valor As String)
    focusAndSend hWnd, "MSMaskWndClass", 5, formatarData(valor)
End Sub

Private Sub preencherAliq(ByVal hWnd As LongPtr, valor As String)
    focusAndSend hWnd, "MSMaskWndClass", 17, valor
End Sub

Private Sub preencherDDF( _
    ByVal hWnd As LongPtr, _
    inciso As String, _
    colunas() As String, _
    linha() As String _
)
    Dim i As Integer
    For i = 0 To UBound(colunas)
        Dim valor As String
        valor = linha(i)
        
        Select Case colunas(i)
        Case "tributo"
            preencherTributo hWnd, valor
        Case "dci"
            preencherDci hWnd, valor
        Case "dij"
            preencherDij hWnd, valor, inciso = "I"
        Case "dij-nc"
            preencherDij hWnd, valor, False
        Case "dcm"
            preencherDcm hWnd, valor
        Case "basico"
            preencherBasico hWnd, valor
        Case "davb"
            preencherDavb hWnd, valor
        Case "dfg"
            preencherDfg hWnd, valor
        Case "aliq"
            preencherAliq hWnd, valor
        End Select
    Next
End Sub

Private Sub preencherDDF_VIIa(ByVal hWnd As LongPtr, linha() As String)
    Dim l As Integer
    l = Len(linha(1))
    ' tipo
    focusAndSend hWnd, "ThunderRT6ComboBox", 5, IIf(l > 0, "{HOME}", "{HOME}{DOWN}{DOWN}{DOWN}")
    Sleep 300
    If l > 0 Then
        preencherDcm hWnd, linha(0)
        preencherBasico hWnd, linha(1)
        preencherDavb hWnd, linha(2)
    End If
End Sub

Private Sub enviarLinha( _
    ByVal hWnd As LongPtr, _
    inciso As String, _
    alinea As String, _
    acao As String, _
    colunas() As String, _
    linha() As String _
)
    Select Case UCase(inciso) & "-" & UCase(alinea)
    Case "VII-A"
        preencherDDF_VIIa hWnd, linha
    Case Else
        preencherDDF hWnd, inciso, colunas, linha
    End Select
    
    Select Case acao
    Case "incluir"
        controlClick hWnd, "ThunderRT6CommandButton", 11
    Case "alterar"
        controlClick hWnd, "ThunderRT6CommandButton", 12
    End Select
End Sub

Public Sub enviarValores()
    hWndMain = FindWindowByClass("ThunderRT6MDIForm", "Auto de Infração e Imposição de Multa - AIIM 2003")
    If hWndMain = 0 Then
        MsgBox "Janela do AIIM 2003, com a edição do auto de infração aberta, não encontrada"
        Exit Sub
    End If
    
    Dim inciso As String
    inciso = ActiveSheet.Cells(4, 3).value
    Dim alinea As String
    alinea = ActiveSheet.Cells(5, 3).value
    Dim acao As String
    acao = LCase(ActiveSheet.Cells(6, 3).value)
    Dim tipo As String
    tipo = LCase(ActiveSheet.Cells(7, 3).value)
    
    Dim hWnd As LongPtr
    hWnd = windowFind(hWndMain, "ThunderRT6FormDC", IIf(tipo = "novo", "Auto de Infração - Alterar", "Auto de Infração - Retificar/Ratificar"))
    If hWnd = 0 Then
        MsgBox "Janela ""Auto de Infração - ..."" não encontrada"
        Exit Sub
    End If
    
    Dim colunas() As String
    colunas = carregarColunas(inciso, alinea)

    Dim totalCols As Integer
    totalCols = UBound(colunas) + 1
    Dim linha() As String
    ReDim linha(0 To totalCols - 1)
    
    Dim r As Integer
    For r = 0 To 199
        Dim value As String
        value = Trim(Cells(4 + r, 6).value)
        If Len(value) = 0 Then
            Exit For
        End If
        
        Dim c As Integer
        For c = 0 To totalCols - 1
            linha(c) = Trim(Cells(4 + r, 6 + c).value)
        Next
        
        If acao = "alterar" Then
            listClickFirstRow hWnd, "ListBox", 3
            Sleep 1000
        End If
        
        enviarLinha hWnd, inciso, alinea, acao, colunas(), linha()
        
        Sleep 1000
    Next

End Sub

Private Function carregarColunas( _
    inciso As String, _
    alinea As String _
) As String()
    With Sheets("config")
        Dim r As Integer
        For r = 0 To 255
            Dim inc As String
            inc = Trim(.Cells(3 + r, 3).value)
            If Len(inc) = 0 Then
                Exit For
            ElseIf inc = inciso Then
                Dim alin As String
                alin = Trim(.Cells(3 + r, 4).value)
                If alin = alinea Then
                    carregarColunas = Split(Trim(.Cells(3 + r, 5).value), ";")
                    Exit Function
                End If
            End If
        Next
    End With
    
    carregarColunas = Split("", ";")
    
End Function

Public Sub prepararColunas()
    Dim inciso As String
    inciso = ActiveSheet.Cells(4, 3).value
    Dim alinea As String
    alinea = ActiveSheet.Cells(5, 3).value
    
    Dim colunas() As String
    colunas = carregarColunas(inciso, alinea)
    Dim coluna As Variant
    Dim c As Integer
    c = 0
    For Each coluna In colunas
        ActiveSheet.Cells(3, 6 + c).value = Replace(CStr(coluna), "-nc", "")
        c = c + 1
    Next
                    
End Sub

Public Sub limparDados()
    ActiveSheet.Range("F3", "K203").ClearContents
End Sub

