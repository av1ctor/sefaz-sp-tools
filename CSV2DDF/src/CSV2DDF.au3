; Copyright 2020 by André Vicentini (avtvicentini)

#include <File.au3>
#include <Array.au3>
#include <StringConstants.au3>
#include <Date.au3>
#include <GUIConstantsEx.au3>
#include <MsgBoxConstants.au3>
#include <FileConstants.au3>
#include <EditConstants.au3>
#include <WindowsConstants.au3>
#include <GuiStatusBar.au3>
#include <GuiListView.au3>

Global $isGUI
Global $nomeCsv, $csvEdit
Global $incisoBox, $alineaBox
Global $statusBar
Global $dadosList

main()

func mostrarErro($texto)
	if not $isGUI then
		ConsoleWrite($texto)
	Else
		MsgBox($IDOK, "Erro", $texto)
	EndIf
EndFunc

func showStatus($texto)
	if not $isGUI then
		ConsoleWrite($texto)
	else
		_GUICtrlStatusBar_SetText($statusBar, StringReplace($texto, @TAB, "|"))
	endif
endfunc

Func main()
	$isGUI = false

	if $CmdLine[0] > 3 then
		mostrarErro( "Uso: inciso alinea arquivo.csv")
		Return

	ElseIf $CmdLine[0] <> "" then
		Local $inciso = StringUpper($CmdLine[1])
		Local $alinea = StringUpper($CmdLine[2])
		Local $csv 	= $CmdLine[3]
		Local $linhas = lerCSV($csv)
		if $linhas = Null then
			return
		endif
		preencher($inciso, $alinea, $linhas)

	Else
		$isGUI = True
		DllCall("kernel32.dll", "bool", "FreeConsole")

		Opt("GUIOnEventMode", 1)
		Local $window = GUICreate("CSV2DDF", 600, 520, -1, -1, -1, $WS_EX_ACCEPTFILES)
		GUISetOnEvent($GUI_EVENT_CLOSE, "fecharApp")
		
		$statusBar = _GUICtrlStatusBar_Create($window)
		 _GUICtrlStatusBar_SetParts($statusBar)

		GUICtrlCreateGroup("Opções", 10, 10, 580, 110)

		GUICtrlCreateLabel("Inciso", 20, 30, 60)
		$incisoBox = GUICtrlCreateCombo("Selecione o inciso...", 80, 30, 185, 20)
		GUICtrlSetData($incisoBox, "I|II|III|IV|V|VI|VII|VIII", "")

		GUICtrlCreateLabel("Alínea", 20, 60, 60)
		$alineaBox = GUICtrlCreateCombo("Selecione a alínea...", 80, 60, 185, 20)
		GUICtrlSetData($alineaBox, "a|b|c|d|e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|v|w|x|y|z", "")

		GUICtrlCreateLabel("Arquivo", 20, 90, 60)
		$csvEdit = GUICtrlCreateEdit("Selecione o arquivo CSV...", 80, 90, 400, 20, $ES_READONLY)
		GUICtrlSetState($csvEdit, $GUI_DROPACCEPTED)

		Local $selCsvButton = GUICtrlCreateButton("Selecionar...", 480, 89, 100, 22)
		GUICtrlSetOnEvent($selCsvButton, "selecionarCSV")

		GUICtrlCreateGroup("", -99, -99, 1, 1)
		
		GUICtrlCreateGroup("Dados", 10, 130, 580, 310)

		$dadosList = GUICtrlCreateListView("A        |B        |C        |D        |E        |F        |G        |H        |I        ", 20, 150, 560, 280, -1, $LVS_EX_GRIDLINES)
		
		GUICtrlCreateGroup("", -99, -99, 1, 1)

		Local $procButton = GUICtrlCreateButton("Processar...", 140, 460, 140, 22)
		GUICtrlSetOnEvent($procButton, "processar")

		Local $cancButton = GUICtrlCreateButton("Sair", 300, 460, 140, 22)
		GUICtrlSetOnEvent($cancButton, "fecharApp")

		GUISetState(@SW_SHOW, $window)

		While 1
			Sleep(1000)
		WEnd

	EndIf
EndFunc

Func fecharApp()
	Exit
EndFunc

func processar()
	Local $inciso = GUICtrlRead($incisoBox)
	Local $alinea = GUICtrlRead($alineaBox)

	Local $linhas = lerCSV($nomeCsv)
	if $linhas = Null then
		return
	endif

	preencher($inciso, $alinea, $linhas)
EndFunc

Func criarGrid($linhas)
	_GUICtrlListView_DeleteAllItems($dadosList)
	For $i = 0 to UBound($linhas) - 1
		Local $linha = $linhas[$i]
		Local $colunas = _ArrayToString($linha, "|")
		GUICtrlCreateListViewItem($colunas, $dadosList)
	next
endfunc

Func selecionarCSV()
	 $nomeCsv = FileOpenDialog("Selecione o arquivo CSV", @WorkingDir, "Arquivos CSV (*.csv)", $FD_FILEMUSTEXIST)
	 If @error Then
			$nomeCsv = Null
			return
	EndIf

	GUICtrlSetData($csvEdit, $nomeCsv)
	
	Local $linhas = lerCSV($nomeCsv)
	if $linhas <> Null then
		criarGrid($linhas)
	endif
EndFunc

Func lerCSV($nome)
	Local $linhas
	if _FileReadToArray($nome, $linhas, $FRTA_NOCOUNT + $FRTA_INTARRAYS, ";") = 0 then
		mostrarErro("Falha ao ler arquivo CSV")
		Return Null
	EndIf
	Return $linhas
EndFunc

Func preencher($inciso, $alinea, $linhas)

	Local $hWnd = WinWait("[CLASS:ThunderRT6MDIForm; TITLE:Auto de Infração e Imposição de Multa - AIIM 2003]", "", 3)
	if $hWnd = 0 Then
		mostrarErro("Janela do AIIM 2003, com a edição do auto de infração aberta, não encontrada")
		Return
	EndIf

	For $i = 0 to UBound($linhas) - 1
		Local $linha = $linhas[$i]

		Switch $inciso
		case "I"
			Switch $alinea
			case "A"
					preencherDDF_Ia($hWnd, $linha)
			case "B"
					preencherDDF_Ib($hWnd, $linha)
			case "C"
					preencherDDF_Ic($hWnd, $linha)
			case "L"
					preencherDDF_Il($hWnd, $linha)
			case Else
					mostrarErro("Alínea não suportada")
					Return
			EndSwitch
		case "II"
			Switch $alinea
			case "C"
					preencherDDF_IIc($hWnd, $linha)
			case Else
					mostrarErro("Alínea não suportada")
					Return
			EndSwitch
		case "IV"
			Switch $alinea
			case "A"
					preencherDDF_IVa($hWnd, $linha)
			Case Else
					mostrarErro("Alínea não suportada")
					Return
			EndSwitch
		case "V"
			Switch $alinea
			case "A"
					preencherDDF_Va($hWnd, $linha)
			case "C"
					preencherDDF_Vc($hWnd, $linha)
			case "M"
					preencherDDF_Vm($hWnd, $linha)
			Case Else
					mostrarErro("Alínea não suportada")
					Return
			EndSwitch
		case "VII"
			Switch $alinea
			case "A"
					preencherDDF_VIIa($hWnd, $linha)
			Case Else
					mostrarErro("Alínea não suportada")
					Return
			EndSwitch
		case Else
			mostrarErro("Inciso não suportado")
			Return
		EndSwitch

		Sleep(1000)
	next

EndFunc

func trim($str)
	Return StringStripWS($str, $STR_STRIPLEADING + $STR_STRIPTRAILING)
	;Return $str
EndFunc

Func formatarData($data)
	If StringLen($data) == 7 Then
		local $month = StringRight($data, 2)
		local $year = StringLeft($data, 4)
		Local $days = _DateDaysInMonth($year, $month)
		Return $days & "/" & $month & "/" & StringRight($year, 2)
	Else
		Return StringLeft($data, 6) & StringRight($data, 2)
	EndIf
EndFunc

func formatarDecimal($dec)
	return StringReplace(StringReplace($dec, "R$", ""), ".", "")
EndFunc

Func focusAndSend($hWnd, $id, $text)
	ControlFocus($hWnd, "", $id)
	ControlSend($hWnd, "", $id, $text)
EndFunc

Func waitDialogAndClick($dlgId, $buttonId)
	Local $hWnd = WinWait($dlgId, "", 10)
	if $hWnd = 0 Then
		Return
	EndIf

	ControlClick($hWnd, "", $buttonId)
EndFunc

Func preencherDDF_Ia($hWnd, $linha)
	Local $tributo = formatarDecimal(trim($linha[0]))
	Local $dci = formatarData(trim($linha[1]))
	Local $davb = formatarData(trim($linha[2]))
	showStatus("Tributo:" & $tributo & @TAB & "DCI:" & $dci & @TAB & "DAVB:" & $davb & @CRLF)

	; tributo
	focusAndSend($hWnd, "[CLASS:ThunderRT6TextBox; INSTANCE:13]", $tributo)
	; DCI
	focusAndSend($hWnd, "[CLASS:MSMaskWndClass; INSTANCE:2]", $dci )
	; DAVB
	focusAndSend($hWnd, "[CLASS:MSMaskWndClass; INSTANCE:4]", $davb)
	; incluir
	ControlClick($hWnd, "", "[CLASS:ThunderRT6CommandButton; INSTANCE:11]")
EndFunc

Func preencherDDF_Ib($hWnd, $linha)
	Local $tributo = formatarDecimal(trim($linha[0]))
	Local $dci = formatarData(trim($linha[1]))
	Local $dij = formatarData(trim($linha[2]))
	Local $davb = formatarData(trim($linha[3]))
	showStatus("Tributo:" & $tributo & @TAB & "DCI:" & $dci & @TAB & "DIJ:" & $dij & @TAB & "DAVB:" & $davb & @CRLF)

	; tributo
	focusAndSend($hWnd, "[CLASS:ThunderRT6TextBox; INSTANCE:13]", $tributo)
	; DCI
	focusAndSend($hWnd, "[CLASS:MSMaskWndClass; INSTANCE:2]", $dci )
	; DIJ
	focusAndSend($hWnd, "[CLASS:MSMaskWndClass; INSTANCE:3]", $dij & "{TAB}")
	waitDialogAndClick("[CLASS:#32770; TITLE:AIIM2003]", "[CLASS:Button; INSTANCE:1]")
	; DAVB
	focusAndSend($hWnd, "[CLASS:MSMaskWndClass; INSTANCE:4]", $davb)
	; incluir
	ControlClick($hWnd, "", "[CLASS:ThunderRT6CommandButton; INSTANCE:11]")
EndFunc

Func preencherDDF_Ic($hWnd, $linha)
	Local $tributo = formatarDecimal(trim($linha[0]))
	Local $dci = formatarData(trim($linha[1]))
	Local $dij = formatarData(trim($linha[2]))
	Local $davb = formatarData(trim($linha[3]))
	showStatus("Tributo:" & $tributo & @TAB & "DCI:" & $dci & @TAB & "DIJ:" & $dij & @TAB & "DAVB:" & $davb & @CRLF)

	; tributo
	focusAndSend($hWnd, "[CLASS:ThunderRT6TextBox; INSTANCE:13]", $tributo)
	; DCI
	focusAndSend($hWnd, "[CLASS:MSMaskWndClass; INSTANCE:2]", $dci )
	; DIJ
	focusAndSend($hWnd, "[CLASS:MSMaskWndClass; INSTANCE:3]", $dij & "{TAB}")
	waitDialogAndClick("[CLASS:#32770; TITLE:AIIM2003]", "[CLASS:Button; INSTANCE:1]")
	; DAVB
	focusAndSend($hWnd, "[CLASS:MSMaskWndClass; INSTANCE:4]", $davb)
	; incluir
	ControlClick($hWnd, "", "[CLASS:ThunderRT6CommandButton; INSTANCE:11]")
EndFunc

Func preencherDDF_Il($hWnd, $linha)
	Local $tributo = formatarDecimal(trim($linha[0]))
	Local $dci = formatarData(trim($linha[1]))
	Local $dij = formatarData(trim($linha[2]))
	Local $davb = formatarData(trim($linha[3]))
	showStatus("Tributo:" & $tributo & @TAB & "DCI:" & $dci & @TAB & "DIJ:" & $dij & @TAB & "DAVB:" & $davb & @CRLF)

	; tributo
	focusAndSend($hWnd, "[CLASS:ThunderRT6TextBox; INSTANCE:13]", $tributo)
	; DCI
	focusAndSend($hWnd, "[CLASS:MSMaskWndClass; INSTANCE:2]", $dci )
	; DIJ
	focusAndSend($hWnd, "[CLASS:MSMaskWndClass; INSTANCE:3]", $dij & "{TAB}")
	waitDialogAndClick("[CLASS:#32770; TITLE:AIIM2003]", "[CLASS:Button; INSTANCE:1]")
	; DAVB
	focusAndSend($hWnd, "[CLASS:MSMaskWndClass; INSTANCE:4]", $davb)
	; incluir
	ControlClick($hWnd, "", "[CLASS:ThunderRT6CommandButton; INSTANCE:11]")
EndFunc

Func preencherDDF_IIc($hWnd, $linha)
	Local $tributo = formatarDecimal(trim($linha[0]))
	Local $dci = formatarData(trim($linha[1]))
	Local $dij = formatarData(trim($linha[2]))
	Local $dcm = formatarData(trim($linha[3]))
	Local $basico = formatarDecimal(trim($linha[4]))
	Local $davb = formatarData(trim($linha[5]))
	showStatus("Tributo:" & $tributo & @TAB & "DCI:" & $dci & @TAB & "DIJ:" & $dij & @TAB & "DCM:" & $dcm & @TAB & "Valor:" & $basico & @TAB & "DAVB:" & $davb & @CRLF)

	; tributo
	focusAndSend($hWnd, "[CLASS:ThunderRT6TextBox; INSTANCE:13]", $tributo)
	; DCI
	focusAndSend($hWnd, "[CLASS:MSMaskWndClass; INSTANCE:2]", $dci )
	; DIJ
	focusAndSend($hWnd, "[CLASS:MSMaskWndClass; INSTANCE:3]", $dij)
	; DCM
	focusAndSend($hWnd, "[CLASS:MSMaskWndClass; INSTANCE:1]", $dcm)
	; valor básico
	focusAndSend($hWnd, "[CLASS:ThunderRT6TextBox; INSTANCE:14]", $basico)
	; DAVB
	focusAndSend($hWnd, "[CLASS:MSMaskWndClass; INSTANCE:4]", $davb)
	; incluir
	ControlClick($hWnd, "", "[CLASS:ThunderRT6CommandButton; INSTANCE:11]")
EndFunc

Func preencherDDF_IVa($hWnd, $linha)
	Local $dcm = formatarData(trim($linha[0]))
	Local $basico = formatarDecimal(trim($linha[1]))
	Local $davb = formatarData(trim($linha[2]))
	showStatus("DCM:" & $dcm & @TAB & "Valor:" & $basico & @TAB & "DAVB:" & $davb & @CRLF)

	; DCM
	focusAndSend($hWnd, "[CLASS:MSMaskWndClass; INSTANCE:1]", $dcm)
	; valor básico
	focusAndSend($hWnd, "[CLASS:ThunderRT6TextBox; INSTANCE:14]", $basico)
	; DAVB
	focusAndSend($hWnd, "[CLASS:MSMaskWndClass; INSTANCE:4]", $davb)
	; incluir
	ControlClick($hWnd, "", "[CLASS:ThunderRT6CommandButton; INSTANCE:11]")
EndFunc

Func preencherDDF_Va($hWnd, $linha)
	Local $dcm = formatarData(trim($linha[0]))
	Local $basico = formatarDecimal(trim($linha[1]))
	Local $davb = formatarData(trim($linha[2]))
	showStatus("DCM:" & $dcm & @TAB & "Valor:" & $basico & @TAB & "DAVB:" & $davb & @CRLF)

	; DCM
	focusAndSend($hWnd, "[CLASS:MSMaskWndClass; INSTANCE:1]", $dcm)
	; valor básico
	focusAndSend($hWnd, "[CLASS:ThunderRT6TextBox; INSTANCE:14]", $basico)
	; DAVB
	focusAndSend($hWnd, "[CLASS:MSMaskWndClass; INSTANCE:4]", $davb)
	; incluir
	ControlClick($hWnd, "", "[CLASS:ThunderRT6CommandButton; INSTANCE:11]")
EndFunc

Func preencherDDF_Vc($hWnd, $linha)
	Local $dcm = formatarData(trim($linha[0]))
	Local $basico = formatarDecimal(trim($linha[1]))
	Local $davb = formatarData(trim($linha[2]))
	showStatus("DCM:" & $dcm & @TAB & "Valor:" & $basico & @TAB & "DAVB:" & $davb & @CRLF)

	; DCM
	focusAndSend($hWnd, "[CLASS:MSMaskWndClass; INSTANCE:1]", $dcm)
	; valor básico
	focusAndSend($hWnd, "[CLASS:ThunderRT6TextBox; INSTANCE:14]", $basico)
	; DAVB
	focusAndSend($hWnd, "[CLASS:MSMaskWndClass; INSTANCE:4]", $davb)
	; incluir
	ControlClick($hWnd, "", "[CLASS:ThunderRT6CommandButton; INSTANCE:11]")
EndFunc

Func preencherDDF_Vm($hWnd, $linha)
	Local $dcm = formatarData(trim($linha[0]))
	Local $basico = formatarDecimal(trim($linha[1]))
	Local $davb = formatarData(trim($linha[2]))
	showStatus("DCM:" & $dcm & @TAB & "Valor:" & $basico & @TAB & "DAVB:" & $davb & @CRLF)

	; DCM
	focusAndSend($hWnd, "[CLASS:MSMaskWndClass; INSTANCE:1]", $dcm)
	; valor básico
	focusAndSend($hWnd, "[CLASS:ThunderRT6TextBox; INSTANCE:14]", $basico)
	; DAVB
	focusAndSend($hWnd, "[CLASS:MSMaskWndClass; INSTANCE:4]", $davb)
	; incluir
	ControlClick($hWnd, "", "[CLASS:ThunderRT6CommandButton; INSTANCE:11]")
EndFunc

Func preencherDDF_VIIa($hWnd, $linha)
	Local $len = StringLen($linha[1])
	; tipo
	focusAndSend($hWnd, "[CLASS:ThunderRT6ComboBox; INSTANCE:5]", ($len > 0? "{HOME}": "{HOME}{DOWN 3}"))
	Sleep(300)
	If $len > 0 Then
		Local $dcm = formatarData(trim($linha[0]))
		Local $basico = formatarDecimal(trim($linha[1]))
		Local $davb = formatarData(trim($linha[2]))
		showStatus("DCM:" & $dcm & @TAB & "Valor:" & $basico & @TAB & "DAVB:" & $davb & @CRLF)

		; DCM
		focusAndSend($hWnd, "[CLASS:MSMaskWndClass; INSTANCE:1]", $dcm)
		; valor básico
		focusAndSend($hWnd, "[CLASS:ThunderRT6TextBox; INSTANCE:14]", $basico)
		; DAVB
		focusAndSend($hWnd, "[CLASS:MSMaskWndClass; INSTANCE:4]", $davb)
	EndIf
	; incluir
	ControlClick($hWnd, "", "[CLASS:ThunderRT6CommandButton; INSTANCE:11]")
EndFunc