'' Copyright 2022 by André Vicentini (avtvicentini)

Option Explicit

#If VBA7 And Win64 Then
    Private Declare PtrSafe Sub Sleep Lib "kernel32" (ByVal dwMilliseconds As Long)
#Else
    Private Declare Sub Sleep Lib "kernel32" (ByVal dwMilliseconds As Long)
#End If

#If VBA7 Then
Private Declare PtrSafe Function WideCharToMultiByte Lib "kernel32" ( _
    ByVal CodePage As Long, _
    ByVal dwFlags As Long, _
    ByVal lpWideCharStr As LongPtr, _
    ByVal cchWideChar As Long, _
    ByVal lpMultiByteStr As LongPtr, _
    ByVal cbMultiByte As Long, _
    ByVal lpDefaultChar As Long, _
    ByVal lpUsedDefaultChar As Long _
    ) As Long
#Else
Private Declare Function WideCharToMultiByte Lib "kernel32" ( _
    ByVal CodePage As Long, _
    ByVal dwFlags As Long, _
    ByVal lpWideCharStr As Long, _
    ByVal cchWideChar As Long, _
    ByVal lpMultiByteStr As Long, _
    ByVal cbMultiByte As Long, _
    ByVal lpDefaultChar As Long, _
    ByVal lpUsedDefaultChar As Long _
    ) As Long
#End If

Private Const CP_UTF8 = 65001
Private Const TAMANHO_MAXIMO = 8388608
Private Const senhaDeProtecao = "sefazsp1234"

Private ie As SHDocVw.InternetExplorer

Private Sub IE_Sledgehammer()
    Dim objWMI As Object, objProcess As Object, objProcesses As Object
    Set objWMI = GetObject("winmgmts://.")
    Set objProcesses = objWMI.ExecQuery( _
        "SELECT * FROM Win32_Process WHERE Name = 'iexplore.exe'")
    For Each objProcess In objProcesses
        Call objProcess.Terminate
    Next
    Set objProcesses = Nothing: Set objWMI = Nothing
End Sub


Private Function readFile(ByVal path As String) As Byte()
    Dim num As Long
    Dim contents() As Byte
    num = FreeFile
    If LenB(Dir(path)) Then
        Open path For Binary Access Read As num
        ReDim contents(LOF(num) - 1&) As Byte
        Get num, , contents
        Close num
    Else
        Err.Raise 53
    End If
    readFile = contents
    Erase contents
End Function

Private Function base64Encode(arr() As Byte) As String
  Dim objXML As Variant
  Dim objNode As Variant

  Set objXML = CreateObject("MSXML2.DOMDocument")
  Set objNode = objXML.createElement("b64")

  objNode.DataType = "bin.base64"
  objNode.nodeTypedValue = arr
  base64Encode = Replace(objNode.Text, vbLf, "")

  Set objNode = Nothing
  Set objXML = Nothing
End Function

Private Sub pauseUntilIeReady(ieObj As InternetExplorerMedium)
    While ieObj.Busy Or ieObj.readyState <> READYSTATE_COMPLETE
        DoEvents
    Wend
End Sub

Private Function getIEWindowFromTitle( _
    title As String, _
    Optional caseSensitive As Boolean = False, _
    Optional exact As Boolean = False _
) As SHDocVw.InternetExplorer

    Dim windows As New SHDocVw.ShellWindows
    Dim win As SHDocVw.InternetExplorer
    
    For Each win In windows
        If checkIEWindowTitle(win, title, caseSensitive, exact) Then
            pauseUntilIeReady win
            Set getIEWindowFromTitle = win
            Exit Function
        End If
    Next

    Set getIEWindowFromTitle = Nothing

End Function

Private Function checkIEWindowTitle( _
    win As SHDocVw.InternetExplorer, _
    title As String, _
    caseSensitive As Boolean, _
    exact As Boolean _
) As Boolean

    On Local Error GoTo handler
    
    If TypeName(win.Document) = "HTMLDocument" Then
        If exact Then
            If (win.Document.title = title) Or ((Not caseSensitive) And (LCase(title) = LCase(win.Document.title))) Then
                checkIEWindowTitle = True
                Exit Function
            End If
        Else
            If InStr(1, win.Document.title, title) Or ((Not caseSensitive) And (InStr(1, LCase(win.Document.title), LCase(title), vbTextCompare) <> 0)) Then
                checkIEWindowTitle = True
                Exit Function
            End If
        End If
    End If

handler:
    checkIEWindowTitle = False
End Function

Private Function Utf8BytesFromString(strInput As String) As Byte()
    Dim nBytes As Long
    Dim abBuffer() As Byte
    Utf8BytesFromString = vbNullString
    If Len(strInput) < 1 Then Exit Function
    nBytes = WideCharToMultiByte(CP_UTF8, 0&, StrPtr(strInput), -1, 0&, 0&, 0&, 0&)
    ReDim abBuffer(nBytes - 2)
    nBytes = WideCharToMultiByte(CP_UTF8, 0&, StrPtr(strInput), -1, VarPtr(abBuffer(0)), nBytes - 1, 0&, 0&)
    Utf8BytesFromString = abBuffer
End Function

'' from: https://stackoverflow.com/questions/49059375/uploading-file-to-website
Private Sub submitForm( _
    ie As SHDocVw.InternetExplorer, _
    url As String, _
    form As Scripting.Dictionary _
)
    Const Boundary As String = "---------------------------0123456789012"

    Dim d As String

    Dim key As Variant
    For Each key In form.keys
        d = d + "--" + Boundary + vbCrLf
        d = d + "Content-Disposition: form-data; name=""" & key & """"
        
        Dim value As Variant
        If TypeOf form(key) Is FileInput Then
            d = d + "; filename=""" + StrConv(Utf8BytesFromString(form(key).path), vbUnicode) + """" + vbCrLf
            d = d + "Content-Type: " & form(key).typ
            value = form(key).contents
        Else
            value = form(key)
        End If
        
        d = d + vbCrLf + vbCrLf + value + vbCrLf
        Set value = Nothing
    Next

    d = d + "--" + Boundary + "--" + vbCrLf
    
    Dim data() As Byte
    ReDim data(Len(d) - 1)
    data = StrConv(d, vbFromUnicode)

    ie.Navigate url, , , data, "Content-Type: multipart/form-data; boundary=" + Boundary + vbCrLf

End Sub

Public Sub carregarAiim()
    On Local Error GoTo handler
    
    IE_Sledgehammer
    
    '' carregar página inicial do e-pat
    Dim ieMain As InternetExplorerMedium
    Set ieMain = New InternetExplorerMedium
    ieMain.Visible = True
    ieMain.Navigate "https://ipe-workspace.intra.fazenda.sp.gov.br/TIBCOiPClnt/Account/Login.aspx"
    
    pauseUntilIeReady ieMain
    
    Dim body As String
    body = ieMain.Document.body.innerText
    If InStr(1, body, "Não é possível acessar esta página") > 0 Then
        Exit Sub
    End If
    
    '' aguardar usuário abrir o AIIM
    Set ie = Nothing
    Do
        Sleep 500
        Set ie = getIEWindowFromTitle("Item de Trabalho")
    Loop While ie Is Nothing
    
    pauseUntilIeReady ie
    
    '' recarregar página, porque é criado um iframe e por questão de seguraça não temos acesso a ele
    Dim url As String
    url = ie.Document.getElementById("workitemiframe").src
    
    ie.Navigate url
    pauseUntilIeReady ie
    
    Exit Sub
    
handler:
    
End Sub

Public Sub selecionarArquivos()
    Dim fso As Object
    Set fso = CreateObject("Scripting.FileSystemObject")
    
    Dim fDialog As FileDialog
    Set fDialog = Application.FileDialog(msoFileDialogFilePicker)
    With fDialog
        .AllowMultiSelect = True
        .title = "Selecione os arquivos"
        .Filters.Clear
        .Filters.Add "Arquivos PDF", "*.pdf"

        If .Show = True Then
            limparArquivos
        
            Dim fPath As Variant
            Dim r As Integer
            r = 0
            For Each fPath In .SelectedItems
                Cells(4 + r, 8).value = fPath
                
                Dim fname As String
                fname = fso.GetFilename(fPath)
                Cells(4 + r, 6).value = fname
                Cells(4 + r, 6).Interior.Color = RGB(255, 255, 255)
                Cells(4 + r, 6).BorderAround LineStyle:=xlContinuous, Weight:=xlThin
                
                Dim f As Object
                Set f = fso.GetFile(fPath)
                Dim estado As String
                estado = "Selecionado"
                Dim cor As Long
                cor = RGB(64, 192, 255)
                If f.Size > TAMANHO_MAXIMO Then
                    estado = "Tamanho inválido"
                    cor = RGB(255, 64, 64)
                End If
                
                Cells(4 + r, 7).HorizontalAlignment = xlCenter
                Cells(4 + r, 7).value = estado
                Cells(4 + r, 7).Interior.Color = cor
                Cells(4 + r, 7).BorderAround LineStyle:=xlContinuous, Weight:=xlThin
                
                Set f = Nothing
                r = r + 1
            Next
        End If
    End With
End Sub

Private Function getElementById(doc As Object, id As String) As Object
    On Local Error GoTo handler
    
    Set getElementById = doc.getElementById(id)
    Exit Function
    
handler:
    Set getElementById = Nothing
End Function

Private Function enviarArquivo( _
    path As String, _
    fname As String _
) As Boolean
    On Local Error GoTo handler
    
    Dim elements(0 To 3) As String
    elements(0) = "__EVENTARGUMENT"
    elements(1) = "__VIEWSTATE"
    elements(2) = "__VIEWSTATEGENERATOR"
    elements(3) = "__EVENTVALIDATION"
    
    Dim contents() As Byte
    contents = readFile(path)
   
    Dim doc As Object
    Set doc = ie.Document
    
    Dim form As Scripting.Dictionary
    Set form = New Scripting.Dictionary
    
    form.Add "__EVENTTARGET", "ctl00$ConteudoPagina$btnInserir"
    form.Add "__LASTFOCUS", ""
    
    Dim elm As Variant
    For Each elm In elements
        form.Add elm, doc.getElementById(elm).value
    Next
    
    form.Add "ctl00$ConteudoPagina$ddlTpDocmnt", "2"
    form.Add "ctl00$ConteudoPagina$ftbObsrvc", ""
    
    Dim i As Integer
    For i = 5 To 10005
        Dim num As String
        num = IIf(i < 10, Format(i, "00"), Trim(Str(i)))
        Dim ordElm As Object
        Set ordElm = getElementById(doc, "ctl00_ConteudoPagina_AdicionarPecas_gvLista_ctl" & num & "_txtOrdem")
        If ordElm Is Nothing Then
            Exit For
        End If
        form.Add "ctl00$ConteudoPagina$AdicionarPecas$gvLista$ctl" & num & "$txtOrdem", ordElm.value
    Next

    Dim fi As FileInput
    Set fi = New FileInput
    fi.path = path
    fi.contents = StrConv(contents, vbUnicode)
    fi.typ = "application/pdf"
    
    form.Add "ctl00$ConteudoPagina$uploadClient", fi
    
    submitForm ie, "https://sefaznet11.intra.fazenda.sp.gov.br/IProcess/ePAT/WebPages/PAT/PrimeiraInstancia/FechamentoAIIM.aspx", form
    
    pauseUntilIeReady ie
    
    Dim errorMsg As String
    errorMsg = Trim(ie.Document.getElementById("ctl00_lblErro").innerText)
    If Len(errorMsg) > 0 Then
        enviarArquivo = False
    ElseIf InStr(1, doc.body.innerText, fname) = 0 Then
        enviarArquivo = False
    Else
        enviarArquivo = True
    End If
    
    Exit Function

handler:
    enviarArquivo = False
End Function

Public Sub enviarArquivos()
    If ie Is Nothing Then
        MsgBox "O AIIM não foi aberto corretamente no e-Pat. Execute o passo 1"
        Exit Sub
    End If
    
    Dim i As Integer
    i = 0
    Do While i < 10000
        Dim state As String
        state = Trim(Cells(4 + i, 7).value)
        If Len(state) = 0 Then
            Exit Do
        ElseIf state = "Selecionado" Then
            Dim path As String
            path = Cells(4 + i, 8).value
            Dim fname As String
            fname = Cells(4 + i, 6).value
            
            Cells(4 + i, 7).value = "Enviando..."
            Cells(4 + i, 7).Interior.Color = RGB(244, 177, 131)
            
            If enviarArquivo(path, fname) Then
                Cells(4 + i, 7).value = "Inserido"
                Cells(4 + i, 7).Interior.Color = RGB(64, 255, 192)
            Else
                Cells(4 + i, 7).value = "Envio falhou"
                Cells(4 + i, 7).Interior.Color = RGB(255, 64, 64)
            End If
        End If
        
        i = i + 1
    Loop
End Sub

Public Sub limparArquivos()
    Range("f4:h10000").Clear
End Sub

Public Sub protegerPlanilha()
    Sheets(1).Protect senhaDeProtecao, UserInterfaceOnly:=True
End Sub

Public Sub desprotegerPlanilha()
    Sheets(1).Unprotect senhaDeProtecao, UserInterfaceOnly:=True
End Sub
