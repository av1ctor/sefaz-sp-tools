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

	if $CmdLine[0] > 1 then
		mostrarErro( "Uso: arquivo.csv")
		Return
		
	ElseIf $CmdLine[0] <> "" then
		Local $csv = $CmdLine[1]
		Local $linhas = lerCSV($csv)
		preencher($linhas)
		
	else
		$isGUI = True
		DllCall("kernel32.dll", "bool", "FreeConsole")

		Opt("GUIOnEventMode", 1)
		Local $window = GUICreate("CSV2OPS", 600, 520, -1, -1, -1, $WS_EX_ACCEPTFILES)
		GUISetOnEvent($GUI_EVENT_CLOSE, "fecharApp")

		$statusBar = _GUICtrlStatusBar_Create($window)
		 _GUICtrlStatusBar_SetParts($statusBar)

		GUICtrlCreateGroup("Opções", 10, 10, 580, 110)

		GUICtrlCreateLabel("Arquivo", 20, 90, 60)
		$csvEdit = GUICtrlCreateEdit("Selecione o arquivo CSV...", 80, 90, 400, 20, $ES_READONLY)
		GUICtrlSetState($csvEdit, $GUI_DROPACCEPTED)

		Local $selCsvButton = GUICtrlCreateButton("Selecionar...", 480, 89, 100, 22)
		GUICtrlSetOnEvent($selCsvButton, "selecionarCSV")

		GUICtrlCreateGroup("", -99, -99, 1, 1)
		
		GUICtrlCreateGroup("Dados", 10, 130, 580, 310)

		$dadosList = GUICtrlCreateListView("Data|Valor", 20, 150, 560, 280, -1, $LVS_EX_GRIDLINES)
		
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
	Local $linhas = lerCSV($nomeCsv)
	if $linhas = Null then
		return
	endif

	preencher($linhas)
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

Func preencher($linhas)
	Local $hWnd = WinWait("[CLASS:ThunderRT6MDIForm; TITLE:Auto de Infração e Imposição de Multa - AIIM 2003]", "", 3)
	if $hWnd = 0 Then
		mostrarErro("Janela do AIIM 2003, com a edição do auto de infração aberta, não encontrada")
		Return
	EndIf

	For $i = 0 to UBound($linhas) - 1
		Local $colunas = $linhas[$i]
		preencherMes($hWnd, $colunas)
		Sleep(1000)
	next

EndFunc

func trim($str)
	Return StringStripWS($str, $STR_STRIPLEADING + $STR_STRIPTRAILING)
EndFunc

Func getMesFromData($data)
	Return Number(StringRight($data, 2))
EndFunc

Func getAnoFromData($data)
	Return Number(StringLeft($data, 4))
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

Func preencherMes($hWnd, $colunas)
	Local $mes = getMesFromData(trim($colunas[0]))
	Local $ano = getAnoFromData(trim($colunas[0]))
	Local $valor = formatarDecimal(trim($colunas[1]))
	showStatus("Mês:" & $mes & @TAB & "Ano:" & $ano & @TAB & "Valor:" & $valor & @CRLF)

	local $anoAtual = Number(@YEAR)

	; mês
	focusAndSend($hWnd, "[CLASS:ThunderRT6ComboBox; INSTANCE:2]", ($mes == 1? "{HOME}": "{HOME}{DOWN " & ($mes-1) & "}"))
	; ano
	focusAndSend($hWnd, "[CLASS:ThunderRT6ComboBox; INSTANCE:1]", ($ano == $anoAtual? "{HOME}": "{HOME}{DOWN " & ($anoAtual-$ano) & "}"))
	; valor
	focusAndSend($hWnd, "[CLASS:ThunderRT6TextBox; INSTANCE:5]", $valor)
	; incluir
	ControlClick($hWnd, "", "[CLASS:ThunderRT6CommandButton; INSTANCE:4]")
EndFunc
