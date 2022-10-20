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
Private colunas() As String
Private inciso As String
Private alinea As String

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
    If hWnd <> 0 Then
        EnumChildWindows hWnd, AddressOf controlFindCB, VarPtr(params)
    Else
        EnumWindows AddressOf controlFindCB, VarPtr(params)
    End If
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
    If hWnd <> 0 Then
        EnumChildWindows hWnd, AddressOf windowFindCB, VarPtr(params)
    Else
        EnumWindows AddressOf windowFindCB, VarPtr(params)
    End If
    windowFind = params.hWnd
End Function

Private Function windowFindWaiting(ByVal hWnd As LongPtr, class As String, title As String, ByVal seconds As Integer) As LongPtr
    Dim elapsed As Integer
    elapsed = 0
    
    Do While elapsed < seconds
        Dim child As LongPtr
        child = windowFind(hWnd, class, title)
        If child <> 0 Then
            windowFindWaiting = child
            Exit Function
        End If
        Sleep 1000
        elapsed = elapsed + 1
    Loop
    
    windowFindWaiting = 0
    
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

Private Sub waitDialogAndClick(hWnd As LongPtr, class As String, title As String, buttonClass As String, ByVal buttonInstance As Integer)
    Dim hWndDlg As LongPtr
    hWndDlg = windowFindWaiting(hWnd, class, title, 10)
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

Private Sub preencherDDF_Ia(ByVal hWnd As LongPtr, linha() As String)
    Dim tributo As String
    Dim dci As String
    Dim davb As String
    tributo = formatarDecimal(Trim(linha(0)))
    dci = formatarData(Trim(linha(1)))
    davb = formatarData(Trim(linha(2)))

    ' tributo
    focusAndSend hWnd, "ThunderRT6TextBox", 13, tributo
    ' DCI
    focusAndSend hWnd, "MSMaskWndClass", 2, dci
    ' DAVB
    focusAndSend hWnd, "MSMaskWndClass", 4, davb
    ' incluir
    controlClick hWnd, "ThunderRT6CommandButton", 11
End Sub

Private Sub preencherDDF_Ib(ByVal hWnd As LongPtr, linha() As String)
    Dim tributo As String
    tributo = formatarDecimal(Trim(linha(0)))
    Dim dci As String
    dci = formatarData(Trim(linha(1)))
    Dim dij As String
    dij = formatarData(Trim(linha(2)))
    Dim davb As String
    davb = formatarData(Trim(linha(3)))

    ' tributo
    focusAndSend hWnd, "ThunderRT6TextBox", 13, tributo
    ' DCI
    focusAndSend hWnd, "MSMaskWndClass", 2, dci
    ' DIJ
    focusAndSend hWnd, "MSMaskWndClass", 3, dij & "{TAB}"
    '
    Sleep 100
    waitDialogAndClick 0, "#32770", "AIIM2003", "Button", 1
    Sleep 100
    ' DAVB
    focusAndSend hWnd, "MSMaskWndClass", 4, davb
    ' incluir
    controlClick hWnd, "ThunderRT6CommandButton", 11
End Sub

Private Sub preencherDDF_Ic(ByVal hWnd As LongPtr, linha() As String)
    Dim tributo As String
    tributo = formatarDecimal(Trim(linha(0)))
    Dim dci As String
    dci = formatarData(Trim(linha(1)))
    Dim dij As String
    dij = formatarData(Trim(linha(2)))
    Dim davb As String
    davb = formatarData(Trim(linha(3)))

    ' tributo
    focusAndSend hWnd, "ThunderRT6TextBox", 13, tributo
    ' DCI
    focusAndSend hWnd, "MSMaskWndClass", 2, dci
    ' DIJ
    focusAndSend hWnd, "MSMaskWndClass", 3, dij & "{TAB}"
    '
    waitDialogAndClick hWnd, "#32770", "AIIM2003", "Button", 1
    ' DAVB
    focusAndSend hWnd, "MSMaskWndClass", 4, davb
    ' incluir
    controlClick hWnd, "ThunderRT6CommandButton", 11
End Sub

Private Sub preencherDDF_Il(ByVal hWnd As LongPtr, linha() As String)
    Dim tributo As String
    tributo = formatarDecimal(Trim(linha(0)))
    Dim dci As String
    dci = formatarData(Trim(linha(1)))
    Dim dij As String
    dij = formatarData(Trim(linha(2)))
    Dim davb As String
    davb = formatarData(Trim(linha(3)))

    ' tributo
    focusAndSend hWnd, "ThunderRT6TextBox", 13, tributo
    ' DCI
    focusAndSend hWnd, "MSMaskWndClass", 2, dci
    ' DIJ
    focusAndSend hWnd, "MSMaskWndClass", 3, dij & "{TAB}"
    '
    waitDialogAndClick hWnd, "#32770", "AIIM2003", "Button", 1
    ' DAVB
    focusAndSend hWnd, "MSMaskWndClass", 4, davb
    ' incluir
    controlClick hWnd, "ThunderRT6CommandButton", 11
End Sub

Private Sub preencherDDF_IIc(ByVal hWnd As LongPtr, linha() As String)
    Dim tributo As String
    tributo = formatarDecimal(Trim(linha(0)))
    Dim dci As String
    dci = formatarData(Trim(linha(1)))
    Dim dij As String
    dij = formatarData(Trim(linha(2)))
    Dim dcm As String
    dcm = formatarData(Trim(linha(3)))
    Dim basico As String
    basico = formatarDecimal(Trim(linha(4)))
    Dim davb As String
    davb = formatarData(Trim(linha(5)))

    ' tributo
    focusAndSend hWnd, "ThunderRT6TextBox", 13, tributo
    ' DCI
    focusAndSend hWnd, "MSMaskWndClass", 2, dci
    ' DIJ
    focusAndSend hWnd, "MSMaskWndClass", 3, dij
    ' DCM
    focusAndSend hWnd, "MSMaskWndClass", 1, dcm
    ' valor básico
    focusAndSend hWnd, "ThunderRT6TextBox", 14, basico
    ' DAVB
    focusAndSend hWnd, "MSMaskWndClass", 4, davb
    ' incluir
    controlClick hWnd, "ThunderRT6CommandButton", 11
End Sub

Private Sub preencherDDF_IVa(ByVal hWnd As LongPtr, linha() As String)
    Dim dcm As String
    dcm = formatarData(Trim(linha(0)))
    Dim basico As String
    basico = formatarDecimal(Trim(linha(1)))
    Dim davb As String
    davb = formatarData(Trim(linha(2)))

    ' DCM
    focusAndSend hWnd, "MSMaskWndClass", 1, dcm
    ' valor básico
    focusAndSend hWnd, "ThunderRT6TextBox", 14, basico
    ' DAVB
    focusAndSend hWnd, "MSMaskWndClass", 4, davb
    ' incluir
    controlClick hWnd, "ThunderRT6CommandButton", 11
End Sub

Private Sub preencherDDF_Va(ByVal hWnd As LongPtr, linha() As String)
    Dim dcm As String
    dcm = formatarData(Trim(linha(0)))
    Dim basico As String
    basico = formatarDecimal(Trim(linha(1)))
    Dim davb As String
    davb = formatarData(Trim(linha(2)))

    ' DCM
    focusAndSend hWnd, "MSMaskWndClass", 1, dcm
    ' valor básico
    focusAndSend hWnd, "ThunderRT6TextBox", 14, basico
    ' DAVB
    focusAndSend hWnd, "MSMaskWndClass", 4, davb
    ' incluir
    controlClick hWnd, "ThunderRT6CommandButton", 11
End Sub

Private Sub preencherDDF_Vc(ByVal hWnd As LongPtr, linha() As String)
    Dim dcm As String
    dcm = formatarData(Trim(linha(0)))
    Dim basico As String
    basico = formatarDecimal(Trim(linha(1)))
    Dim davb As String
    davb = formatarData(Trim(linha(2)))

    ' DCM
    focusAndSend hWnd, "MSMaskWndClass", 1, dcm
    ' valor básico
    focusAndSend hWnd, "ThunderRT6TextBox", 14, basico
    ' DAVB
    focusAndSend hWnd, "MSMaskWndClass", 4, davb
    ' incluir
    controlClick hWnd, "ThunderRT6CommandButton", 11
End Sub

Private Sub preencherDDF_Vm(ByVal hWnd As LongPtr, linha() As String)
    Dim dcm As String
    dcm = formatarData(Trim(linha(0)))
    Dim basico As String
    basico = formatarDecimal(Trim(linha(1)))
    Dim davb As String
    davb = formatarData(Trim(linha(2)))

    ' DCM
    focusAndSend hWnd, "MSMaskWndClass", 1, dcm
    ' valor básico
    focusAndSend hWnd, "ThunderRT6TextBox", 14, basico
    ' DAVB
    focusAndSend hWnd, "MSMaskWndClass", 4, davb
    ' incluir
    controlClick hWnd, "ThunderRT6CommandButton", 11
End Sub

Private Sub preencherDDF_VIIa(ByVal hWnd As LongPtr, linha() As String)
    Dim l As Integer
    l = Len(linha(1))
    ' tipo
    focusAndSend hWnd, "ThunderRT6ComboBox", 5, IIf(l > 0, "{HOME}", "{HOME}{DOWN}{DOWN}{DOWN}")
    Sleep 300
    If l > 0 Then
        Dim dcm As String
        dcm = formatarData(Trim(linha(0)))
        Dim basico As String
        basico = formatarDecimal(Trim(linha(1)))
        Dim davb As String
        davb = formatarData(Trim(linha(2)))

        ' DCM
        focusAndSend hWnd, "MSMaskWndClass", 1, dcm
        ' valor básico
        focusAndSend hWnd, "ThunderRT6TextBox", 14, basico
        ' DAVB
        focusAndSend hWnd, "MSMaskWndClass", 4, davb
    End If
    ' incluir
    controlClick hWnd, "ThunderRT6CommandButton", 11
End Sub

Private Sub enviarLinha(ByVal hWnd As LongPtr, linha() As String)
    Select Case UCase(inciso)
    Case "I"
        Select Case UCase(alinea)
        Case "A"
            preencherDDF_Ia hWnd, linha
        Case "B"
            preencherDDF_Ib hWnd, linha
        Case "C"
            preencherDDF_Ic hWnd, linha
        Case "L"
            preencherDDF_Il hWnd, linha
        End Select
    Case "II"
        Select Case UCase(alinea)
        Case "C"
            preencherDDF_IIc hWnd, linha
        End Select
    Case "IV"
        Select Case UCase(alinea)
        Case "A"
            preencherDDF_IVa hWnd, linha
        End Select
    Case "V"
        Select Case UCase(alinea)
        Case "A"
            preencherDDF_Va hWnd, linha
        Case "C"
            preencherDDF_Vc hWnd, linha
        Case "M"
            preencherDDF_Vm hWnd, linha
        End Select
    Case "VII"
        Select Case UCase(alinea)
        Case "A"
            preencherDDF_VIIa hWnd, linha
        End Select
    End Select
End Sub

Public Sub enviarValores()
    hWndMain = FindWindowByClass("ThunderRT6MDIForm", "Auto de Infração e Imposição de Multa - AIIM 2003")
    If hWndMain = 0 Then
        MsgBox "Janela do AIIM 2003, com a edição do auto de infração aberta, não encontrada"
        Exit Sub
    End If
    
    Dim hWnd As LongPtr
    hWnd = windowFind(hWndMain, "ThunderRT6FormDC", "Auto de Infração - Alterar")
    If hWnd = 0 Then
        MsgBox "Janela ""Auto de Infração - Alterar"" não encontrada"
        Exit Sub
    End If
    
    prepararColunas

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
        
        enviarLinha hWnd, linha()
        
        Sleep 1000
    Next

End Sub

Public Sub prepararColunas()
    inciso = ActiveSheet.Cells(4, 3).value
    alinea = ActiveSheet.Cells(5, 3).value
    
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
                    colunas = Split(Trim(.Cells(3 + r, 5).value), ";")
                    Dim coluna As Variant
                    Dim c As Integer
                    c = 0
                    For Each coluna In colunas
                        ActiveSheet.Cells(3, 6 + c).value = CStr(coluna)
                        c = c + 1
                    Next
                    Exit For
                End If
            End If
        Next
        
    End With
End Sub

Public Sub limparDados()
    ActiveSheet.Range("F3", "K203").ClearContents
End Sub

