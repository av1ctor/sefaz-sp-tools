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
Private Const TAMANHO_MAXIMO = 10485760
Private Const senhaDeProtecao = "sefazsp1234"

Private ie As InternetExplorerMedium
Public especiePadrao As String
Public assuntoPadrao As String
Public usuario As String
Public senha As String

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

Private Sub pauseUntilIeReady(ieObj As InternetExplorerMedium)
    On Local Error GoTo handler
    
    While ieObj.Busy Or ieObj.readyState <> READYSTATE_COMPLETE
        DoEvents
    Wend
    
handler:
End Sub

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

Private Function prepareFormWithFilesField( _
    key As Variant, _
    value As Variant, _
    boundary As String _
) As String

    Dim d As String
    d = "--" + boundary + vbCrLf
    d = d + "Content-Disposition: form-data; name=""" & key & """"
        
    Dim realValue As Variant
    If TypeOf value Is FileInput Then
        d = d + "; filename=""" + StrConv(Utf8BytesFromString(value.path), vbUnicode) + """" + vbCrLf
        d = d + "Content-Type: " & value.typ
        realValue = value.contents
    Else
        Dim s As String
        s = CStr(value)
        If Len(s) > 0 Then
            realValue = StrConv(Utf8BytesFromString(s), vbUnicode)
        Else
            realValue = s
        End If
    End If
    
    d = d + vbCrLf + vbCrLf + realValue + vbCrLf
    Set realValue = Nothing
    
    prepareFormWithFilesField = d
    
End Function

Private Sub submitFormWithFiles( _
    ie As InternetExplorerMedium, _
    url As String, _
    form As Scripting.Dictionary _
)
    Const boundary As String = "---------------------------0123456789012"

    Dim d As String

    Dim key As Variant
    For Each key In form.keys
        If IsArray(form(key)) Then
            Dim item As Variant
            For Each item In form(key)
                d = d + prepareFormWithFilesField(key, item, boundary)
            Next
        Else
            d = d + prepareFormWithFilesField(key, form(key), boundary)
        End If
    Next

    d = d + "--" + boundary + "--" + vbCrLf
    
    Dim data() As Byte
    ReDim data(Len(d) - 1)
    data = StrConv(d, vbFromUnicode)

    ie.Navigate url, , , data, "Content-Type: multipart/form-data; boundary=" + boundary + vbCrLf

End Sub

Private Function prepareFormField( _
    key As Variant, _
    value As Variant _
) As String

    prepareFormField = key & "=" & WorksheetFunction.EncodeURL(value)
    
End Function

Private Sub submitForm( _
    ie As InternetExplorerMedium, _
    url As String, _
    form As Scripting.Dictionary _
)
    Dim d As String

    Dim key As Variant
    For Each key In form.keys
        Dim value As Variant
        value = form(key)
                
        If IsArray(value) Then
            Dim item As Variant
            For Each item In value
                If d <> "" Then
                    d = d & "&"
                End If
                d = d & prepareFormField(key, item)
            Next
        Else
            If d <> "" Then
                d = d & "&"
            End If
            d = d & prepareFormField(key, value)
        End If
        
        Set value = Nothing
    Next

    Dim data() As Byte
    ReDim data(Len(d) - 1)
    data = StrConv(d, vbFromUnicode)

    ie.Navigate url, , , data, "Content-type: application/x-www-form-urlencoded" + vbCrLf

End Sub

Public Sub showLogon()
    LogonForm.Show
End Sub

Public Function fazerLogon( _
    username As String, _
    password As String _
) As Boolean
    'On Local Error GoTo handler
    
    fazerLogon = False
    
    IE_Sledgehammer
    
    Set ie = New InternetExplorerMedium
    ie.Visible = False
    
    Dim form As Scripting.Dictionary
    Set form = New Scripting.Dictionary
    
    form.Add "username", username
    form.Add "password", password
    
    submitForm ie, "https://www.documentos.spsempapel.sp.gov.br/siga/public/app/login?cont=https://www.documentos.spsempapel.sp.gov.br/siga/app/principal?redirecionar=false", form
    pauseUntilIeReady ie
    
    If InStr(1, ie.LocationURL, "app/login") > 0 Then
        Set ie = Nothing
        Exit Function
    End If
    
    '' salvar
    usuario = username
    senha = password
    
    fazerLogon = True
    Exit Function
    
handler:
    
End Function

Public Sub selecionarArquivos()
    Dim fso As Scripting.FileSystemObject
    Set fso = New Scripting.FileSystemObject
    
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
                Cells(4 + r, 10).value = fPath
                
                Dim fname As String
                fname = fso.GetFilename(fPath)
                Cells(4 + r, 6).value = fname
                Cells(4 + r, 6).Interior.Color = RGB(255, 255, 255)
                Cells(4 + r, 6).BorderAround LineStyle:=xlContinuous, Weight:=xlThin
                
                Dim fnameWithoutExt As String
                fnameWithoutExt = Replace(fname, "." & fso.GetExtensionName(fPath), "")
                
                Cells(4 + r, 7).value = Replace(assuntoPadrao, "{nome}", fnameWithoutExt)
                Cells(4 + r, 7).Interior.Color = RGB(255, 255, 255)
                Cells(4 + r, 7).BorderAround LineStyle:=xlContinuous, Weight:=xlThin
                
                Cells(4 + r, 8).value = especiePadrao
                Cells(4 + r, 8).Interior.Color = RGB(255, 255, 255)
                Cells(4 + r, 8).BorderAround LineStyle:=xlContinuous, Weight:=xlThin
                
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
                
                Cells(4 + r, 9).HorizontalAlignment = xlCenter
                Cells(4 + r, 9).value = estado
                Cells(4 + r, 9).Interior.Color = cor
                Cells(4 + r, 9).BorderAround LineStyle:=xlContinuous, Weight:=xlThin
                
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

Private Function getElementByName(doc As Object, name As String) As Object
    On Local Error GoTo handler
    
    Set getElementByName = doc.getElementsByName(name)(0)
    Exit Function
    
handler:
    Set getElementByName = Nothing
End Function

Public Sub selecionarExpedientes()
    ExpedienteForm.Show
End Sub

Public Function listarExpedientes() As Expediente()
    Dim expedientes() As Expediente
    
    If ie Is Nothing Then
        MsgBox "Logon falhou. Execute o passo 1"
        listarExpedientes = expedientes
        Exit Function
    End If
    
    ie.Navigate "https://www.documentos.spsempapel.sp.gov.br/siga/app/principal?redirecionar=false"
    pauseUntilIeReady ie
    
    Sleep 2000
    
    Dim body As String
    body = ie.Document.body.innerHtml
    
    Dim s As Integer
    s = InStr(1, body, "ultMovRespSel.id=")
    If s = 0 Then
        MsgBox "Não foi possível listar os expedientes do usuário"
        listarExpedientes = expedientes
        Exit Function
    End If
        
    Dim e As Integer
    e = InStr(s, body, "&")
    
    Dim usuarioId As String
    usuarioId = Mid(body, s + 17, e - (s + 17))

    ie.Navigate "https://www.documentos.spsempapel.sp.gov.br/sigaex/app/expediente/doc/listar?ultMovIdEstadoDoc=2&ultMovRespSel.id=" & usuarioId
    pauseUntilIeReady ie
    
    Dim i As Integer
    i = 0
    
    Dim elm As Object
    For Each elm In ie.Document.getElementsByTagName("a")
        Dim href As String
        If InStr(1, elm.href, "/sigaex/app/expediente/doc/exibir?sigla=") > 0 Then
            Dim sigla As String
            sigla = Trim(elm.innerText)
            Dim dup As Boolean
            dup = False
            Dim j As Integer
            For j = 0 To i - 1
                If expedientes(j).sigla = sigla Then
                    dup = True
                    Exit For
                End If
            Next
            If Not dup Then
                ReDim Preserve expedientes(0 To i)
                
                Dim desc As String
                
                Dim text As String
                text = elm.ParentNode.ParentNode.innerText
                s = InStr(1, text, "Complemento do Assunto: ")
                If s > 0 Then
                    desc = Trim(Mid(text, s + 24))
                End If
                
                Set expedientes(i) = New Expediente
                expedientes(i).sigla = sigla
                expedientes(i).descricao = desc
                
                i = i + 1
            End If
        End If
    Next
    
    listarExpedientes = expedientes
    
End Function

Private Function enviarArquivo( _
    path As String, _
    fname As String, _
    assunto As String, _
    especie As String, _
    form As Scripting.Dictionary _
) As String
    'On Local Error GoTo handler
    
    form.item("Assunto") = assunto
    form.item("especie") = especie
    
    Dim contents() As Byte
    contents = readFile(path)
   
    Dim fi As FileInput
    Set fi = New FileInput
    fi.path = path
    fi.contents = StrConv(contents, vbUnicode)
    fi.typ = "application/pdf"
    
    form.Remove "arquivo"
    form.Add "arquivo", fi
    
    submitFormWithFiles ie, "https://www.documentos.spsempapel.sp.gov.br/sigaex/app/expediente/doc/gravar", form
    pauseUntilIeReady ie
    
    Dim s As Integer
    s = InStr(1, ie.LocationURL, "doc/exibir?sigla=")
    If s = 0 Then
        enviarArquivo = ""
        Exit Function
    End If
    
    Dim e As Integer
    e = InStr(s, ie.LocationURL, "&")
    
    enviarArquivo = Mid(ie.LocationURL, s + 17, e - (s + 17))
    Exit Function

handler:
    enviarArquivo = ""
End Function
    

Private Function prepararForm( _
    sigla As String _
) As Scripting.Dictionary

    Dim inputs(0 To 42) As String
    inputs(0) = "exDocumentoDTO.tamanhoMaximoDescricao"
    inputs(1) = "exDocumentoDTO.alterouModelo"
    inputs(2) = "hasPai"
    inputs(3) = "isPaiEletronico"
    inputs(4) = "postback"
    inputs(5) = "exDocumentoDTO.sigla"
    inputs(6) = "exDocumentoDTO.nomePreenchimento"
    inputs(7) = "exDocumentoDTO.autuando"
    inputs(8) = "exDocumentoDTO.criandoAnexo"
    inputs(9) = "exDocumentoDTO.criandoSubprocesso"
    inputs(10) = "exDocumentoDTO.idMobilAutuado"
    inputs(11) = "exDocumentoDTO.id"
    inputs(12) = "exDocumentoDTO.dtDocString"
    inputs(13) = "exDocumentoDTO.nivelAcesso"
    inputs(14) = "exDocumentoDTO.eletronico"
    inputs(15) = "cliente"
    inputs(16) = "exDocumentoDTO.desativarDocPai"
    inputs(17) = "reqexDocumentoDTO.mobilPaiSel"
    inputs(18) = "exDocumentoDTO.mobilPaiSel.buscar"
    inputs(19) = "reqexDocumentoDTO.subscritorSel"
    inputs(20) = "exDocumentoDTO.subscritorSel.buscar"
    inputs(21) = "reqexDocumentoDTO.titularSel"
    inputs(22) = "exDocumentoDTO.titularSel.id"
    inputs(23) = "exDocumentoDTO.titularSel.descricao"
    inputs(24) = "exDocumentoDTO.titularSel.buscar"
    inputs(25) = "exDocumentoDTO.titularSel.sigla"
    inputs(26) = "exDocumentoDTO.nmFuncaoSubscritor"
    inputs(27) = "reqexDocumentoDTO.classificacaoSel"
    inputs(28) = "exDocumentoDTO.classificacaoSel.descricao"
    inputs(29) = "exDocumentoDTO.classificacaoSel.buscar"
    inputs(30) = "obrigatorios"
    inputs(31) = "exDocumentoDTO.mobilPaiSel.id"
    inputs(32) = "exDocumentoDTO.mobilPaiSel.descricao"
    inputs(33) = "exDocumentoDTO.subscritorSel.id"
    inputs(34) = "exDocumentoDTO.subscritorSel.descricao"
    inputs(35) = "exDocumentoDTO.subscritorSel.sigla"
    inputs(36) = "exDocumentoDTO.descrDocumento"
    inputs(37) = "Assunto"
    inputs(38) = "especie"
    inputs(39) = "exDocumentoDTO.classificacaoSel.id"
    inputs(40) = "exDocumentoDTO.idMod.original"
    inputs(41) = "exDocumentoDTO.idMod"
    inputs(42) = "exDocumentoDTO.idTpDoc"
        
    ie.Navigate "https://www.documentos.spsempapel.sp.gov.br/sigaex/app/expediente/doc/editar?mobilPaiSel.sigla=" & sigla & "&criandoAnexo=true"
    pauseUntilIeReady ie
    
    Dim doc As Object
    Set doc = ie.Document
    
    Dim form As Scripting.Dictionary
    Set form = New Scripting.Dictionary
    
    Dim inp As Variant
    For Each inp In inputs
        Dim elm As Object
        Set elm = getElementByName(doc, CStr(inp))
        If Not elm Is Nothing Then
            form.Add inp, elm.value
        Else
            form.Add inp, ""
        End If
        Set elm = Nothing
    Next
    
    Dim clickSelect(0 To 1) As Variant
    clickSelect(0) = ""
    clickSelect(1) = ""
    form.Add "clickSelect", clickSelect
    
    Dim campos(0 To 15) As Variant
    campos(0) = "criandoAnexo"
    campos(1) = "criandoSubprocesso"
    campos(2) = "autuando"
    campos(3) = "idMobilAutuado"
    campos(4) = "idTpDoc"
    campos(5) = "dtDocString"
    campos(6) = "nivelAcesso"
    campos(7) = "eletronico"
    campos(8) = "subscritorSel.id"
    campos(9) = "substituicao"
    campos(10) = "personalizacao"
    campos(11) = "titularSel.id"
    campos(12) = "nmFuncaoSubscritor"
    campos(13) = "tipoDestinatario"
    campos(14) = "classificacaoSel.id"
    campos(15) = "descrDocumento"
    form.Add "campos", campos
    
    Dim alterouSel(0 To 3) As Variant
    alterouSel(0) = ""
    alterouSel(1) = ""
    alterouSel(2) = ""
    alterouSel(3) = ""
    form.Add "alterouSel", alterouSel
    
    Dim vars(0 To 1) As Variant
    vars(0) = "Assunto"
    vars(1) = "especie"
    form.Add "vars", vars
    
    form.item("exDocumentoDTO.classificacaoSel.descricao") = "Documento capturado"
    form.item("exDocumentoDTO.classificacaoSel.id") = "14630"
    form.item("exDocumentoDTO.idMod.original") = "109823"
    form.item("exDocumentoDTO.idMod") = "109823"
    form.item("exDocumentoDTO.idTpDoc") = "5"
    
    Dim fi As FileInput
    Set fi = New FileInput
    form.Add "arquivo", fi
    
    Set prepararForm = form
    
End Function

Private Function assinarDocumento( _
    sigla As String _
) As Boolean
    
    Dim form As Scripting.Dictionary
    Set form = New Scripting.Dictionary
    
    form.Add "id", "undefined"
    form.Add "sigla", Replace(sigla, "-", "")
    form.Add "nomeUsuarioSubscritor", usuario
    form.Add "senhaUsuarioSubscritor", senha
    form.Add "senhaIsPin", "false"
    form.Add "copia", "false"
    form.Add "juntar", "true"
    
    submitForm ie, "https://www.documentos.spsempapel.sp.gov.br/sigaex/app/expediente/mov/assinar_senha_gravar", form
    pauseUntilIeReady ie
    
    Dim resp As String
    resp = ie.Document.body.innerText
    
    If InStr(1, resp, "HTTP 500") > 0 Then
        assinarDocumento = False
        Exit Function
    End If
    
    assinarDocumento = True
    
End Function

Public Sub enviarArquivos()
    If ie Is Nothing Then
        MsgBox "Logon falhou. Execute o passo 1"
        Exit Sub
    End If
    
    Dim Expediente As String
    Expediente = Replace(Replace(Trim(ActiveSheet.Shapes("expedienteField").OLEFormat.Object.text), vbLf, ""), vbCr, "")
    If Len(Expediente) = 0 Then
        MsgBox "Preechimento do campo Expediente é obrigatório. Execute o passo 2"
        Exit Sub
    End If
    
    Dim form As Scripting.Dictionary
    Set form = prepararForm(Expediente)
    
    Dim i As Integer
    i = 0
    Do While i < 10000
        Dim state As String
        state = Trim(Cells(4 + i, 9).value)
        If Len(state) = 0 Then
            Exit Do
        ElseIf state = "Selecionado" Then
            Dim path As String
            path = Cells(4 + i, 10).value
            Dim fname As String
            fname = Cells(4 + i, 6).value
            Dim assunto As String
            assunto = Cells(4 + i, 7).value
            Dim especie As String
            especie = Cells(4 + i, 8).value
            
            Cells(4 + i, 9).value = "Enviando..."
            Cells(4 + i, 9).Interior.Color = RGB(244, 177, 131)
            
            Dim tmpSigla As String
            tmpSigla = enviarArquivo(path, fname, assunto, especie, form)
            
            If Len(tmpSigla) > 0 Then
                Cells(4 + i, 9).value = "Incluído"
                Cells(4 + i, 9).Interior.Color = RGB(64, 255, 192)
            Else
                Cells(4 + i, 9).value = "Envio falhou"
                Cells(4 + i, 9).Interior.Color = RGB(255, 64, 64)
            End If
            
            If Len(tmpSigla) > 0 Then
                If Not assinarDocumento(tmpSigla) Then
                    Cells(4 + i, 9).value = "Assinatura falhou"
                    Cells(4 + i, 9).Interior.Color = RGB(255, 64, 64)
                Else
                    Cells(4 + i, 9).value = "Assinado"
                    Cells(4 + i, 9).Interior.Color = RGB(64, 255, 192)
                End If
            End If
        End If
        
        i = i + 1
    Loop
End Sub

Public Sub configurar()
    ConfigForm.Show
End Sub

Public Sub limparArquivos()
    Range("f4:j10000").Clear
End Sub

Public Sub protegerPlanilha()
    Sheets(1).Protect senhaDeProtecao, UserInterfaceOnly:=True
End Sub

Public Sub desprotegerPlanilha()
    Sheets(1).Unprotect senhaDeProtecao, UserInterfaceOnly:=True
End Sub
