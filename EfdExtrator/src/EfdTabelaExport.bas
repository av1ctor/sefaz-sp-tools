#include once "EfdTabelaExport.bi"
#include once "vbcompat.bi"
#include once "libs/trycatch.bi"

''''''''
constructor EfdTabelaExport(nomeArquivo as String, opcoes as OpcoesExtracao ptr)
	this.nomeArquivo = nomeArquivo
	this.opcoes = opcoes
	
	ew = new TableWriter()

	entradas = null
	saidas = null
end constructor

''''''''
destructor EfdTabelaExport()
	if ew <> null then
		delete ew
	end if
end destructor

''''''''
function EfdTabelaExport.withCallbacks(onProgress as OnProgressCB, onError as OnErrorCB) as EfdTabelaExport ptr
	ew->withCallbacks(onProgress, onError)
	this.onProgress = onProgress
	this.onError = onError
	return @this
end function

''''''''
function EfdTabelaExport.withLua(lua as lua_State ptr, customLuaCbDict as TDict ptr) as EfdTabelaExport ptr
	this.lua = lua
	this.customLuaCbDict = customLuaCbDict
	return @this
end function

''''''''
function EfdTabelaExport.withState(itemNFeSafiFornecido as boolean) as EfdTabelaExport ptr
	this.itemNFeSafiFornecido = itemNFeSafiFornecido
	return @this
end function

''''''''
function EfdTabelaExport.withFiltros( _
		filtrarPorCnpj as OnFilterByStrCB, _
		filtrarPorChave as OnFilterByStrCB _
	) as EfdTabelaExport ptr
	this.filtrarPorCnpj = filtrarPorCnpj
	this.filtrarPorChave = filtrarPorChave
	return @this
end function

''''''''
function EfdTabelaExport.withDicionarios( _
		participanteDict as TDict ptr, _
		itemIdDict as TDict ptr, _
		chaveDFeDict as TDict ptr, _
		infoComplDict as TDict ptr, _
		obsLancamentoDict as TDict ptr, _
		bemCiapDict as TDict ptr _
	) as EfdTabelaExport ptr
	this.participanteDict = participanteDict
	this.itemIdDict = itemIdDict
	this.chaveDFeDict = chaveDFeDict
	this.infoComplDict = infoComplDict
	this.obsLancamentoDict = obsLancamentoDict
	this.bemCiapDict = bemCiapDict
	return @this
end function

''''''''
function EfdTabelaExport.criar() as boolean
	return ew->create(nomeArquivo, opcoes->formatoDeSaida)
end function

''''''''
function EfdTabelaExport.getPlanilha(nome as const zstring ptr) as TableTable ptr
		select case lcase(*nome)
		case "entradas"
			return entradas
		case "saidas"
			return saidas
		case "inconsistencias lre"
			return inconsistenciasLRE
		case "inconsistencias lrs"
			return inconsistenciasLRS
		case "resumos lre"
			return resumosLRE
		case "resumos lrs"
			return resumosLRS
		case "ciap"
			return ciap
		case "estoque"
			return estoque
		case "producao"
			return producao
		case "inventario"
			return inventario
		case else
			return null
		end select
end function

''''''''
private sub adicionarColunasComuns(sheet as TableTable ptr, ehEntrada as Boolean)
	var row = sheet->addRow(true)

	sheet->addColumn(CT_STRING, 0, 14)
	row->addCell("CNPJ " + iif(ehEntrada, "Emitente", "Destinatario"))
	sheet->addColumn(CT_STRING, 0, 18)
	row->addCell("IE " + iif(ehEntrada, "Emitente", "Destinatario"))
	sheet->addColumn(CT_STRING, 4, 2)
	row->addCell("UF " + iif(ehEntrada, "Emitente", "Destinatario"))
	sheet->addColumn(CT_STRING, 30, 100)
	row->addCell("Razao Social " + iif(ehEntrada, "Emitente", "Destinatario"))
	sheet->addColumn(CT_STRING, 4, 2)
	row->addCell("Modelo")
	sheet->addColumn(CT_STRING, 6, 3)
	row->addCell("Serie")
	sheet->addColumn(CT_INTNUMBER)
	row->addCell("Numero")
	sheet->addColumn(CT_DATE)
	row->addCell("Data Emissao")
	sheet->addColumn(CT_DATE)
	row->addCell("Data " + iif(ehEntrada, "Entrada", "Saida"))
	sheet->addColumn(CT_STRING, 45, 44)
	row->addCell("Chave")
	sheet->addColumn(CT_STRING, 6, 16)
	row->addCell("Situacao")
	sheet->addColumn(CT_MONEY)
	row->addCell("BC ICMS")
	sheet->addColumn(CT_NUMBER)
	row->addCell("Aliq ICMS")
	sheet->addColumn(CT_MONEY)
	row->addCell("Valor ICMS")
	sheet->addColumn(CT_MONEY)
	row->addCell("BC ICMS ST")
	sheet->addColumn(CT_NUMBER)
	row->addCell("Aliq ICMS ST")
	sheet->addColumn(CT_MONEY)
	row->addCell("Valor ICMS ST")
	sheet->addColumn(CT_MONEY)
	row->addCell("Valor IPI")
	sheet->addColumn(CT_MONEY)
	row->addCell("Valor Item")
	sheet->addColumn(CT_INTNUMBER)
	row->addCell("Nro Item")
	sheet->addColumn(CT_NUMBER)
	row->addCell("Qtd")
	sheet->addColumn(CT_STRING, 4, 32)
	row->addCell("Unidade")
	sheet->addColumn(CT_INTNUMBER)
	row->addCell("CFOP")
	sheet->addColumn(CT_INTNUMBER)
	row->addCell("CST")
	sheet->addColumn(CT_INTNUMBER)
	row->addCell("NCM")
	sheet->addColumn(CT_STRING, 0, 60)
	row->addCell("Codigo Item")
	sheet->addColumn(CT_STRING, 30, 254)
	row->addCell("Descricao Item")
	
	if not ehEntrada then
		sheet->addColumn(CT_MONEY)
		row->addCell("DifAl FCP")
		sheet->addColumn(CT_MONEY)
		row->addCell("DifAl ICMS Orig")
		sheet->addColumn(CT_MONEY)
		row->addCell("DifAl ICMS Dest")
	end if
	
	sheet->addColumn(CT_STRING, 40, 254)
	row->addCell("Info. complementares")

	sheet->addColumn(CT_STRING, 40, 254)
	row->addCell("Obs. lancamento")
end sub

private sub criarColunasApuracaoIcms(sheet as TableTable ptr)
	var row = sheet->addRow(true)

	sheet->addColumn(CT_DATE)
	row->addCell("Inicio")
	sheet->addColumn(CT_DATE)
	row->addCell("Fim")
	sheet->addColumn(CT_MONEY)
	row->addCell("Total Debitos")
	sheet->addColumn(CT_MONEY)
	row->addCell("Ajustes Debitos")
	sheet->addColumn(CT_MONEY)
	row->addCell("Total Ajuste Deb")
	sheet->addColumn(CT_MONEY)
	row->addCell("Estornos Credito")
	sheet->addColumn(CT_MONEY)
	row->addCell("Total Creditos")
	sheet->addColumn(CT_MONEY)
	row->addCell("Ajustes Creditos")
	sheet->addColumn(CT_MONEY)
	row->addCell("Total Ajuste Cred")
	sheet->addColumn(CT_MONEY)
	row->addCell("Estornos Debito")
	sheet->addColumn(CT_MONEY)
	row->addCell("Saldo Cred Anterior")
	sheet->addColumn(CT_MONEY)
	row->addCell("Saldo Devedor Apurado")
	sheet->addColumn(CT_MONEY)
	row->addCell("Total Deducoes")
	sheet->addColumn(CT_MONEY)
	row->addCell("ICMS a Recolher")
	sheet->addColumn(CT_MONEY)
	row->addCell("Saldo Credor a Transportar")
	sheet->addColumn(CT_MONEY)
	row->addCell("Deb Extra Apuracao")
	for i as integer = 1 to MAX_AJUSTES
		sheet->addColumn(CT_STRING, 80, 254)
		row->addCell("Detalhe Ajuste " & i)
	next
	
end sub

private sub criarColunasApuracaoIcmsST(sheet as TableTable ptr)
	var row = sheet->addRow(true)

	sheet->addColumn(CT_DATE)
	row->addCell("Inicio")
	sheet->addColumn(CT_DATE)
	row->addCell("Fim")
	sheet->addColumn(CT_STRING, 4, 2)
	row->addCell("UF")
	sheet->addColumn(CT_STRING, 0, 4)
	row->addCell("Movimentacao")
	sheet->addColumn(CT_MONEY)
	row->addCell("Saldo Credor Anterior")
	sheet->addColumn(CT_MONEY)
	row->addCell("Total Devolucao Merc")
	sheet->addColumn(CT_MONEY)
	row->addCell("Total Ressarcimentos")
	sheet->addColumn(CT_MONEY)
	row->addCell("Total Ajustes Cred")
	sheet->addColumn(CT_MONEY)
	row->addCell("Total Ajustes Cred Docs")
	sheet->addColumn(CT_MONEY)
	row->addCell("Total Retencao")
	sheet->addColumn(CT_MONEY)
	row->addCell("Total Ajustes Deb")
	sheet->addColumn(CT_MONEY)
	row->addCell("Total Ajustes Deb Docs")
	sheet->addColumn(CT_MONEY)
	row->addCell("Saldo Devedor ant. Deducoes")
	sheet->addColumn(CT_MONEY)
	row->addCell("Total Deducoes")
	sheet->addColumn(CT_MONEY)
	row->addCell("ICMS a Recolher")
	sheet->addColumn(CT_MONEY)
	row->addCell("Saldo Credor a Transportar")
	sheet->addColumn(CT_MONEY)
	row->addCell("Deb Extra Apuracao")

	for i as integer = 1 to MAX_AJUSTES
		sheet->addColumn(CT_STRING, 80, 254)
		row->addCell("Detalhe Ajuste " & i)
	next
end sub

private sub criarColunasInventario(sheet as TableTable ptr)
	var row = sheet->addRow(true)

	sheet->addColumn(CT_DATE)
	row->addCell("Data Inventario")
	sheet->addColumn(CT_STRING, 0, 60)
	row->addCell("Codigo")
	sheet->addColumn(CT_INTNUMBER)
	row->addCell("NCM")
	sheet->addColumn(CT_INTNUMBER)
	row->addCell("Tipo")
	sheet->addColumn(CT_STRING, 0, 32)
	row->addCell("Tipo (Descricao)")
	sheet->addColumn(CT_STRING, 30, 254)
	row->addCell("Descricao")
	sheet->addColumn(CT_STRING, 6, 32)
	row->addCell("Unidade")
	sheet->addColumn(CT_NUMBER)
	row->addCell("Qtd")
	sheet->addColumn(CT_MONEY)
	row->addCell("Valor Unitario")
	sheet->addColumn(CT_MONEY)
	row->addCell("Valor Item")
	sheet->addColumn(CT_INTNUMBER)
	row->addCell("Ind. Propriedade")
	sheet->addColumn(CT_STRING, 0, 14)
	row->addCell("CNPJ Proprietario")
	sheet->addColumn(CT_STRING, 0, 254)
	row->addCell("Texto Complementar")
	sheet->addColumn(CT_STRING, 0, 60)
	row->addCell("Codigo Conta Contabil")
	sheet->addColumn(CT_MONEY)
	row->addCell("Valor Item IR")
end sub

private sub criarColunasCIAP(sheet as TableTable ptr)
	var row = sheet->addRow(true)

	sheet->addColumn(CT_DATE)
	row->addCell("Data Inicial")
	sheet->addColumn(CT_DATE)
	row->addCell("Data Final")
	sheet->addColumn(CT_MONEY)
	row->addCell("Soma Total Saidas Tributadas")
	sheet->addColumn(CT_MONEY)
	row->addCell("Soma Total Saidas")
	sheet->addColumn(CT_NUMBER)
	row->addCell("Indice")
	sheet->addColumn(CT_STRING, 0, 60)
	row->addCell("Codigo Bem")
	sheet->addColumn(CT_STRING, 0, 254)
	row->addCell("Descricao Bem")
	sheet->addColumn(CT_DATE)
	row->addCell("Data Movimentacao")
	sheet->addColumn(CT_STRING, 6, 32)
	row->addCell("Tipo Movimentacao")
	sheet->addColumn(CT_MONEY)
	row->addCell("Valor ICMS")
	sheet->addColumn(CT_MONEY)
	row->addCell("Valor ICMS ST")
	sheet->addColumn(CT_MONEY)
	row->addCell("Valor ICMS Frete")
	sheet->addColumn(CT_MONEY)
	row->addCell("Valor ICMS Difal")
	sheet->addColumn(CT_INTNUMBER)
	row->addCell("Num. Parcela")
	sheet->addColumn(CT_MONEY)
	row->addCell("Valor Parcela")
	sheet->addColumn(CT_STRING, 4, 2)
	row->addCell("Modelo")
	sheet->addColumn(CT_STRING, 6, 3)
	row->addCell("Serie")
	sheet->addColumn(CT_INTNUMBER)
	row->addCell("Numero")
	sheet->addColumn(CT_DATE)
	row->addCell("Data Emissao")
	sheet->addColumn(CT_STRING, 30, 44)
	row->addCell("Chave NF-e")
	sheet->addColumn(CT_STRING, 0, 14)
	row->addCell("CNPJ")
	sheet->addColumn(CT_STRING, 0, 20)
	row->addCell("IE")
	sheet->addColumn(CT_STRING, 4, 2)
	row->addCell("UF")
	sheet->addColumn(CT_STRING, 30, 100)
	row->addCell("Razao Social")
	
end sub

private sub criarColunasEstoque(sheet as TableTable ptr)
	var row = sheet->addRow(true)

	sheet->addColumn(CT_DATE)
	row->addCell("Data Inicial")
	sheet->addColumn(CT_DATE)
	row->addCell("Data Final")
	sheet->addColumn(CT_STRING, 0, 60)
	row->addCell("Codigo Item")
	sheet->addColumn(CT_INTNUMBER)
	row->addCell("NCM Item")
	sheet->addColumn(CT_INTNUMBER)
	row->addCell("Tipo Item")
	sheet->addColumn(CT_STRING, 0, 32)
	row->addCell("Tipo Item (Descricao)")
	sheet->addColumn(CT_STRING, 30, 254)
	row->addCell("Descricao Item")
	sheet->addColumn(CT_NUMBER)
	row->addCell("Qtd")
	sheet->addColumn(CT_INTNUMBER)
	row->addCell("Tipo")
	sheet->addColumn(CT_STRING, 0, 14)
	row->addCell("Prop CNPJ")
	sheet->addColumn(CT_STRING, 0, 20)
	row->addCell("Prop IE")
	sheet->addColumn(CT_STRING, 4, 2)
	row->addCell("Prop UF")
	sheet->addColumn(CT_STRING, 30, 100)
	row->addCell("Prop Razao Social")
	
end sub

private sub criarColunasProducao(sheet as TableTable ptr)
	var row = sheet->addRow(true)

	sheet->addColumn(CT_DATE)
	row->addCell("Data Inicial")
	sheet->addColumn(CT_DATE)
	row->addCell("Data Final")
	sheet->addColumn(CT_STRING, 0, 60)
	row->addCell("Codigo Item")
	sheet->addColumn(CT_INTNUMBER)
	row->addCell("NCM Item")
	sheet->addColumn(CT_INTNUMBER)
	row->addCell("Tipo Item")
	sheet->addColumn(CT_STRING, 0, 32)
	row->addCell("Tipo Item (Descricao)")
	sheet->addColumn(CT_STRING, 30, 254)
	row->addCell("Descricao Item")
	sheet->addColumn(CT_NUMBER)
	row->addCell("Qtd")
	sheet->addColumn(CT_STRING, 0, 60)
	row->addCell("Codigo Ordem")
end sub

private sub criarColunasRessarcST(sheet as TableTable ptr)
	var row = sheet->addRow(true)

	sheet->addColumn(CT_STRING, 0, 14)
	row->addCell("CNPJ Emitente Ult NF-e Ent")
	sheet->addColumn(CT_STRING, 0, 20)
	row->addCell("IE Emitente Ult NF-e Ent")
	sheet->addColumn(CT_STRING, 4, 2)
	row->addCell("UF Emitente Ult NF-e Ent")
	sheet->addColumn(CT_STRING, 30, 100)
	row->addCell("Razao Social Emitente Ult NF-e Ent")
	sheet->addColumn(CT_STRING, 4, 2)
	row->addCell("Modelo Ult NF-e Ent")
	sheet->addColumn(CT_STRING, 6, 3)
	row->addCell("Serie Ult NF-e Ent")
	sheet->addColumn(CT_INTNUMBER)
	row->addCell("Numero Ult NF-e Ent")
	sheet->addColumn(CT_DATE)
	row->addCell("Data Emissao Ult NF-e Ent")
	sheet->addColumn(CT_NUMBER)
	row->addCell("Qtd Ult Ent")
	sheet->addColumn(CT_MONEY)
	row->addCell("Valor Ult Ent")
	sheet->addColumn(CT_MONEY)
	row->addCell("BC ICMS ST")
	sheet->addColumn(CT_STRING, 45, 44)
	row->addCell("Chave Ult NF-e Ent")
	sheet->addColumn(CT_INTNUMBER)
	row->addCell("Num Item Ult NF-e Ent")
	sheet->addColumn(CT_MONEY)
	row->addCell("BC ICMS")
	sheet->addColumn(CT_NUMBER)
	row->addCell("Aliq ICMS")
	sheet->addColumn(CT_MONEY)
	row->addCell("Lim BC ICMS")
	sheet->addColumn(CT_MONEY)
	row->addCell("ICMS")
	sheet->addColumn(CT_NUMBER)
	row->addCell("Aliq ICMS ST")
	sheet->addColumn(CT_MONEY)
	row->addCell("Ressarcimento")
	sheet->addColumn(CT_STRING)
	row->addCell("Responsavel")
	sheet->addColumn(CT_STRING)
	row->addCell("Motivo")
	sheet->addColumn(CT_STRING)
	row->addCell("Tipo Doc Arrecad")
	sheet->addColumn(CT_STRING, 0, 32)
	row->addCell("Num Doc Arrecad")
	sheet->addColumn(CT_STRING, 45, 44)
	row->addCell("Chave NF-e Saida")
	sheet->addColumn(CT_INTNUMBER)
	row->addCell("Num Item NF-e Saida")
end sub

sub EfdTabelaExport.criarPlanilhaEntradas()
	entradasCnt += 1
	entradas = ew->addTable("Entradas" & iif(entradasCnt > 1, str(entradasCnt), ""))
	adicionarColunasComuns(entradas, true)
end sub

sub EfdTabelaExport.criarPlanilhaSaidas()
	saidasCnt += 1
	saidas = ew->addTable("Saidas"  & iif(saidasCnt > 1, str(saidasCnt), ""))
	adicionarColunasComuns(saidas, false)
end sub

function EfdTabelaExport.addRowEntradas() as TableRow ptr
	if entradas->nRows = 1048576-1 then
		if opcoes->formatoDeSaida = FT_XLSX then
			criarPlanilhaEntradas()
		end if
	end if
		
	function = entradas->AddRow()
end function

function EfdTabelaExport.addRowSaidas() as TableRow ptr
	if saidas->nRows = 1048576-1 then
		if opcoes->formatoDeSaida = FT_XLSX then
			criarPlanilhaSaidas()
		end if
	end if
		
	function = saidas->AddRow()
end function

''''''''
sub EfdTabelaExport.criarPlanilhas()
	'' planilha de entradas
	criarPlanilhaEntradas()

	'' planilha de saídas
	criarPlanilhaSaidas()

	'' apuração do ICMS
	apuracaoIcms = ew->addTable("Apuracao ICMS")
	criarColunasApuracaoIcms(apuracaoIcms)
   
	'' apuração do ICMS ST
	apuracaoIcmsST = ew->addTable("Apuracao ICMS ST")
	criarColunasApuracaoIcmsST(apuracaoIcmsST)
	
	'' Inventário
	inventario = ew->addTable("Inventario")
	criarColunasInventario(inventario)

	'' CIAP
	ciap = ew->addTable("CIAP")
	criarColunasCIAP(ciap)

	'' Estoque
	estoque = ew->addTable("Estoque")
	criarColunasEstoque(estoque)

	'' Producao
	producao = ew->addTable("Producao")
	criarColunasProducao(producao)

	'' Ressarcimento ST
	ressarcST = ew->addTable("Ressarcimento ST")
	criarColunasRessarcST(ressarcST)
	
	'' Inconsistencias LRE
	inconsistenciasLRE = ew->addTable("Inconsistencias LRE")

	'' Inconsistencias LRS
	inconsistenciasLRS = ew->addTable("Inconsistencias LRS")
	
	'' Resumos LRE
	resumosLRE = ew->addTable("Resumos LRE")

	'' Resumos LRS
	resumosLRS = ew->addTable("Resumos LRS")
	
	''
	lua_getglobal(lua, "criarPlanilhas")
	lua_call(lua, 0, 0)

	lua_setarGlobal(lua, "efd_plan_entradas", entradas)
	lua_setarGlobal(lua, "efd_plan_saidas", saidas)
	
end sub

function EfdTabelaExport.getInfoCompl(info as TDocInfoCompl ptr) as string
	var res = ""
	
	do while info <> null
		var compl = cast( TInfoCompl ptr, infoComplDict->lookup(info->idCompl))
		res += iif(len(res) > 0, ",", "")
		res += "{'descricao':'" + compl->descricao + "'"
		if len(info->extra) > 0 then 
			res += ", 'extra':'" + info->extra + "'"
		end if
		res += "}"
		info = info->next_
	loop
	
	function = res
end function

function EfdTabelaExport.getObsLanc(obs as TDocObs ptr) as string
	var res = ""
	
	do while obs <> null
		var lanc = cast( TObsLancamento ptr, obsLancamentoDict->lookup(obs->idLanc))
		res += iif(len(res) > 0, ",", "")
		res += "{'descricao':'" + lanc->descricao + "'"
		if len(obs->extra) > 0 then 
			res += ", 'extra':'" + obs->extra + "'"
		end if
		var ajuste = obs->ajusteListHead
		if ajuste <> null then
			res += ", 'ajustes':["
			var cnt = 0
			do 
				res += iif(cnt > 0, ",", "")
				res += "{'codigo':'" + ajuste->idAjuste + "'"
				if len(ajuste->extra) > 0 then 
					res += ", 'extra':'" + ajuste->extra + "'"
				end if
				if len(ajuste->idItem) > 0 then 
					res += ", 'item':'" + ajuste->idItem + "'"
				end if
				res += ", 'bc':'" + DBL2MONEYBR(ajuste->bcICMS) + "'"
				res += ", 'aliq':'" + DBL2MONEYBR(ajuste->aliqICMS) + "'"
				res += ", 'valor':'" + DBL2MONEYBR(ajuste->icms) + "'"
				res += ", 'outros':'" + DBL2MONEYBR(ajuste->outros) + "'"
				res += "}"
				cnt += 1
				ajuste = ajuste->next_
			loop while ajuste <> null
			res += "]"
		end if
		res += "}"
		obs = obs->next_
	loop
	
	function = res
end function

''''''''
sub EfdTabelaExport.gerar(regListHead as TRegistro ptr, regMestre as TMestre ptr, nroRegs as integer)
	
	if entradas = null then
		criarPlanilhas()
	end if
	
	onProgress(!"\tGerando planilhas", 0)
	
	dim as TRegistro ptr reg = null
	try
		var regCnt = 0
		reg = regListHead
		do while reg <> null
			'para cada registro..
			select case as const reg->tipo
			'item de NF-e?
			case DOC_NF_ITEM
				var item = cast(TDocNFItem ptr, reg)
				var doc = item->documentoPai
				var part = cast( TParticipante ptr, participanteDict->lookup(doc->idParticipante) )

				var emitirLinha = iif(doc->operacao = SAIDA, not opcoes->pularLrs, not opcoes->pularLre)
				if opcoes->filtrarCnpj andalso emitirLinha then
					if part <> null then
						emitirLinha = filtrarPorCnpj(part->cnpj, opcoes->listaCnpj())
					end if
				end if
				
				if opcoes->filtrarChaves andalso emitirLinha then
					emitirLinha = filtrarPorChave(doc->chave, opcoes->listaChaves())
				end if
				
				if opcoes->somenteRessarcimentoST andalso emitirLinha then
					emitirLinha = item->itemRessarcStListHead <> null
				end if
				
				if emitirLinha then
					'só existe item para entradas (exceto quando há ressarcimento ST)
					dim as TableRow ptr row
					if doc->operacao = ENTRADA then
						row = addRowEntradas()
					else
						row = addRowSaidas()
					end if

					if part <> null then
						row->addCell(iif(len(part->cpf) > 0, part->cpf, part->cnpj))
						row->addCell(part->ie)
						row->addCell(MUNICIPIO2SIGLA(part->municip))
						row->addCell(part->nome)
					else
						row->addCell("")
						row->addCell("")
						row->addCell("")
						row->addCell("")
					end if
					row->addCell(doc->modelo)
					row->addCell(doc->serie)
					row->addCell(doc->numero)
					row->addCell(YyyyMmDd2Datetime(doc->dataEmi))
					row->addCell(YyyyMmDd2Datetime(doc->dataEntSaida))
					row->addCell(doc->chave)
					row->addCell(codSituacao2Str(doc->situacao))
					row->addCell(item->bcICMS)
					row->addCell(item->aliqICMS)
					row->addCell(item->ICMS)
					row->addCell(item->bcICMSST)
					row->addCell(item->aliqICMSST)
					row->addCell(item->ICMSST)
					row->addCell(item->IPI)
					row->addCell(item->valor)
					row->addCell(item->numItem)
					row->addCell(item->qtd)
					row->addCell(item->unidade)
					row->addCell(item->cfop)
					row->addCell(item->cstICMS)
					var itemId = cast( TItemId ptr, itemIdDict->lookup(item->itemId) )
					if itemId <> null then 
						row->addCell(itemId->ncm)
						row->addCell(itemId->id)
						row->addCell(itemId->descricao)
					end if
					row->addCell(getInfoCompl(doc->infoComplListHead))
					row->addCell(getObsLanc(doc->obsListHead))
				end if

			'NF-e?
			case DOC_NF, DOC_NFSCT, DOC_NF_ELETRIC
				var nf = cast(TDocNF ptr, reg)
				if ISREGULAR(nf->situacao) then
					'' NOTA: não existe itemDoc para saídas (exceto quando há ressarcimento ST), só temos informações básicas do DF-e, 
					'' 	     a não ser que sejam carregados os relatórios .csv do SAFI vindos do infoview
					if nf->operacao = SAIDA or (nf->operacao = ENTRADA and nf->nroItens = 0) or reg->tipo <> DOC_NF then
						dim as TDFe_NFe ptr dfe = null
						if itemNFeSafiFornecido and opcoes->acrescentarDados then
							if len(nf->chave) > 0 then
								dfe = cast(TDFe_NFe ptr, chaveDFeDict->lookup(nf->chave))
							end if
						end if

						var part = cast( TParticipante ptr, participanteDict->lookup(nf->idParticipante) )

						var emitirLinhas = (opcoes->somenteRessarcimentoST = false) andalso _
							iif(nf->operacao = SAIDA, not opcoes->pularLrs, not opcoes->pularLre)
						if opcoes->filtrarCnpj andalso emitirLinhas then
							if part <> null then
								emitirLinhas = filtrarPorCnpj(part->cnpj, opcoes->listaCnpj())
							end if
						end if

						if opcoes->filtrarChaves andalso emitirLinhas then
							emitirLinhas = filtrarPorChave(nf->chave, opcoes->listaChaves())
						end if

						var anal = nf->itemAnalListHead
						var analCnt = 1
						
						if emitirLinhas then
							do
								dim as TableRow ptr row
								if nf->operacao = SAIDA then
									row = addRowSaidas()
								else
									row = addRowEntradas()
								end if
							
								if part <> null then
									row->addCell(iif(len(part->cpf) > 0, part->cpf, part->cnpj))
									row->addCell(part->ie)
									row->addCell(MUNICIPIO2SIGLA(part->municip))
									row->addCell(part->nome)
								else
									row->addCell("")
									row->addCell("")
									row->addCell("")
									row->addCell("")
								end if
								row->addCell(nf->modelo)
								row->addCell(nf->serie)
								row->addCell(nf->numero)
								row->addCell(YyyyMmDd2Datetime(nf->dataEmi))
								row->addCell(YyyyMmDd2Datetime(nf->dataEntSaida))
								row->addCell(nf->chave)
								row->addCell(codSituacao2Str(nf->situacao))
								
								if anal = null then
									row->addCell(nf->bcICMS)
									row->addCell("")
									row->addCell(nf->ICMS)
									row->addCell(nf->bcICMSST)
									row->addCell(nf->ICMSST)
									row->addCell("")
									row->addCell(nf->IPI)
									row->addCell(nf->valorTotal)
									for i as integer = 1 to 16-8
										row->addCell("")
									next
								else
									row->addCell(anal->bc)
									row->addCell(anal->aliq)
									row->addCell(anal->ICMS)
									row->addCell(anal->bcST)
									row->addCell("")
									row->addCell(anal->ICMSST)
									row->addCell(anal->IPI)
									row->addCell(anal->valorOp)
									row->addCell(analCnt)
									row->addCell(0)
									row->addCell("")
									row->addCell(anal->cfop)
									row->addCell(anal->cst)
									for i as integer = 1 to 3
										row->addCell("")
									next
									analCnt += 1
								end if

								if nf->operacao = SAIDA then
									row->addCell(nf->difal.fcp)
									row->addCell(nf->difal.icmsOrigem)
									row->addCell(nf->difal.icmsDest)
								end if
								
								row->addCell(getInfoCompl(nf->infoComplListHead))
								row->addCell(getObsLanc(nf->obsListHead))
							
								if anal = null then
									exit do
								end if
								
								'' adicionar informações do DF-e, se tiver sido fornecido
								if dfe <> null then
									var item = dfe->itemListHead
									do while item <> null 
										if item->cfop = anal->cfop andalso _
												item->cst = anal->cst andalso _
													item->aliqICMS = anal->aliq then
											
											row->collapsed = true
											
											dim as TableRow ptr subrow
											if nf->operacao = SAIDA then
												subrow = addRowSaidas()
											else
												subrow = addRowEntradas()
											end if
											
											subrow->level = 1
											
											if part <> null then
												subrow->addCell(iif(len(part->cpf) > 0, part->cpf, part->cnpj))
												subrow->addCell(part->ie)
												subrow->addCell(MUNICIPIO2SIGLA(part->municip))
												subrow->addCell(part->nome)
											else
												subrow->addCell("")
												subrow->addCell("")
												subrow->addCell("")
												subrow->addCell("")
											end if
											
											subrow->addCell(item->modelo)
											subrow->addCell(item->serie)
											subrow->addCell(item->numero)
											subrow->addCell(YyyyMmDd2Datetime(dfe->dataEmi))
											subrow->addCell("")
											subrow->addCell(dfe->chave)
											subrow->addCell("")
											
											subrow->addCell(item->bcICMS)
											subrow->addCell(item->aliqICMS)
											subrow->addCell(item->ICMS)
											subrow->addCell(item->bcICMSST)
											subrow->addCell("")
											subrow->addCell("")
											subrow->addCell(item->IPI)
											subrow->addCell(item->valorProduto)
											subrow->addCell(item->nroItem)
											subrow->addCell(item->qtd)
											subrow->addCell(item->unidade)
											subrow->addCell(item->cfop)
											subrow->addCell(item->cst)
											subrow->addCell(item->ncm)
											subrow->addCell(item->codProduto)
											subrow->addCell(item->descricao)
											
											if opcoes->formatoDeSaida = FT_XLSX then
												'' NOTA: é necessário emitir as linhas do DF-e primeiro, porque agrupamentos no Excel funcionam como subtotais, portanto a linha pai será sempre a última
												if nf->operacao = SAIDA then
													saidas->swapConsecutiveRows(row, subrow)
												else
													entradas->swapConsecutiveRows(row, subrow)
												end if
											end if											
											
										end if
										item = item->next_
									loop 
								end if		
								
								anal = anal->next_
							loop while anal <> null
						end if
					
					end if
			   
				else
					var emitirLinha = (opcoes->somenteRessarcimentoST = false) andalso _
						iif(nf->operacao = SAIDA, not opcoes->pularLrs, not opcoes->pularLre)
					
					if emitirLinha then
						var row = iif(nf->operacao = SAIDA, saidas, entradas)->AddRow()

						row->addCell("")
						row->addCell("")
						row->addCell("")
						row->addCell("")
						row->addCell(nf->modelo)
						row->addCell(nf->serie)
						row->addCell(nf->numero)
						'' NOTA: cancelados e inutilizados não vêm com a data preenchida, então retiramos a data da chave ou do registro mestre
						var dataEmi = iif( len(nf->chave) = 44, "20" + mid(nf->chave,3,2) + mid(nf->chave,5,2) + "01", regMestre->dataIni )
						row->addCell(YyyyMmDd2Datetime(dataEmi))
						row->addCell("")
						row->addCell(nf->chave)
						row->addCell(codSituacao2Str(nf->situacao))
						
						for i as integer = 1 to iif(nf->operacao = SAIDA, 32, 29) - 11
							row->addCell("")
						next
					end if
				end if
				
			'ressarcimento st?
			case DOC_NF_ITEM_RESSARC_ST
				var item = cast(TDocNFItemRessarcSt ptr, reg)
				var part = cast( TParticipante ptr, participanteDict->lookup(item->idParticipanteUlt) )

				var emitirLinha = not opcoes->pularLre
				if opcoes->filtrarCnpj andalso emitirLinha then
					if part <> null then
						emitirLinha = filtrarPorCnpj(part->cnpj, opcoes->listaCnpj())
					end if
				end if

				if emitirLinha then
					var row = ressarcST->AddRow()

					if part <> null then
						row->addCell(iif(len(part->cpf) > 0, part->cpf, part->cnpj))
						row->addCell(part->ie)
						row->addCell(MUNICIPIO2SIGLA(part->municip))
						row->addCell(part->nome)
					else
						row->addCell("")
						row->addCell("")
						row->addCell("")
						row->addCell("")
					end if
					row->addCell(item->modeloUlt)
					row->addCell(item->serieUlt)
					row->addCell(item->numeroUlt)
					row->addCell(YyyyMmDd2Datetime(item->dataUlt))
					row->addCell(item->qtdUlt)
					row->addCell(item->valorUlt)
					row->addCell(item->valorBcST)
					row->addCell(item->chaveNFeUlt)
					row->addCell(item->numItemNFeUlt)
					row->addCell(item->bcIcmsUlt)
					row->addCell(item->aliqIcmsUlt)
					row->addCell(item->limiteBcIcmsUlt)
					row->addCell(item->icmsUlt)
					row->addCell(item->aliqIcmsStUlt)
					row->addCell(item->res)
					row->addCell(item->responsavelRet)
					row->addCell(item->motivo)
					row->addCell(item->tipDocArrecadacao)
					row->addCell(item->numDocArrecadacao)
					row->addCell(item->documentoPai->documentoPai->chave)
					row->addCell(item->documentoPai->numItem)
				end if

			'CT-e?
			case DOC_CT
				var ct = cast(TDocCT ptr, reg)
				if ISREGULAR(ct->situacao) then
					var part = cast( TParticipante ptr, participanteDict->lookup(ct->idParticipante) )

					var emitirLinhas = (opcoes->somenteRessarcimentoST = false) and _
						iif(ct->operacao = SAIDA, not opcoes->pularLrs, not opcoes->pularLre)
					
					if opcoes->filtrarCnpj andalso emitirLinhas then
						if part <> null then
							emitirLinhas = filtrarPorCnpj(part->cnpj, opcoes->listaCnpj())
						end if
					end if

					if opcoes->filtrarChaves andalso emitirLinhas then
						emitirLinhas = filtrarPorChave(ct->chave, opcoes->listaChaves())
					end if
						
					if emitirLinhas then
						dim as TDocItemAnal ptr item = null
						if ct->operacao = ENTRADA then
							item = ct->itemAnalListHead
						end if
						
						var itemCnt = 1
						do
							dim as TableRow ptr row 
							if ct->operacao = SAIDA then
								row = addRowSaidas()
							else
								row = addRowEntradas()
							end if
							
							if part <> null then
								row->addCell(iif(len(part->cpf) > 0, part->cpf, part->cnpj))
								row->addCell(part->ie)
								row->addCell(MUNICIPIO2SIGLA(part->municip))
								row->addCell(part->nome)
							else
								row->addCell("")
								row->addCell("")
								row->addCell("")
								row->addCell("")
							end if
							row->addCell(ct->modelo)
							row->addCell(ct->serie)
							row->addCell(ct->numero)
							row->addCell(YyyyMmDd2Datetime(ct->dataEmi))
							row->addCell(YyyyMmDd2Datetime(ct->dataEntSaida))
							row->addCell(ct->chave)
							row->addCell(codSituacao2Str(ct->situacao))
							
							if item <> null then
								row->addCell(item->bc)
								row->addCell(item->aliq)
								row->addCell(item->ICMS)
								row->addCell("")
								row->addCell("")
								row->addCell("")
								row->addCell("")
								row->addCell(item->valorOp)
								row->addCell(itemCnt)
								row->addCell("")
								row->addCell("")
								row->addCell(item->cfop)
								row->addCell(item->cst)
								row->addCell("")
								row->addCell("")
								row->addCell("")
								
								item = item->next_
								itemCnt += 1
							else
								row->addCell(ct->bcICMS)
								row->addCell("")
								row->addCell(ct->ICMS)
								row->addCell("")
								row->addCell("")
								row->addCell("")
								row->addCell("")
								row->addCell(ct->valorServico)
								row->addCell(1)
								row->addCell("")
								row->addCell("")
								row->addCell("")
								row->addCell("")
								row->addCell("")
								row->addCell("")
								row->addCell("")
								
							end if

							if ct->operacao = SAIDA then
								row->addCell(ct->difal.fcp)
								row->addCell(ct->difal.icmsOrigem)
								row->addCell(ct->difal.icmsDest)
							end if
							
							row->addCell("")
							row->addCell("")
						loop while item <> null
					end if
				
				else
					var emitirLinhas = (opcoes->somenteRessarcimentoST = false) and _
						iif(ct->operacao = SAIDA, not opcoes->pularLrs, not opcoes->pularLre)

					if emitirLinhas then
						var row = iif(ct->operacao = SAIDA, saidas, entradas)->AddRow()

						row->addCell("")
						row->addCell("")
						row->addCell("")
						row->addCell("")
						row->addCell(ct->modelo)
						row->addCell(ct->serie)
						row->addCell(ct->numero)
						'' NOTA: cancelados e inutilizados não vêm com a data preenchida, então retiramos a data da chave ou do registro mestre
						var dataEmi = iif( len(ct->chave) = 44, "20" + mid(ct->chave,3,2) + mid(ct->chave,5,2) + "01", regMestre->dataIni )
						row->addCell(YyyyMmDd2Datetime(dataEmi))
						row->addCell("")
						row->addCell(ct->chave)
						row->addCell(codSituacao2Str(ct->situacao))

						for i as integer = 1 to iif(ct->operacao = SAIDA, 32, 29) - 11
							row->addCell("")
						next
					end if
				
				end if
				
			'item de ECF?
			case DOC_ECF_ITEM
				if not opcoes->pularLrs then
					var item = cast(TDocECFItem ptr, reg)
					var doc = item->documentoPai
					if ISREGULAR(doc->situacao) then
						'só existe cupom para saída
						if doc->operacao = SAIDA then
							var emitirLinha = (opcoes->somenteRessarcimentoST = false)
							if opcoes->filtrarCnpj andalso emitirLinha then
								emitirLinha = filtrarPorCnpj(doc->cpfCnpjAdquirente, opcoes->listaCnpj())
							end if

							if opcoes->filtrarChaves andalso emitirLinha then
								emitirLinha = filtrarPorChave(doc->chave, opcoes->listaChaves())
							end if
							
							if emitirLinha then
								var row = addRowSaidas()

								row->addCell(doc->cpfCnpjAdquirente)
								row->addCell("")
								row->addCell("SP")
								row->addCell(doc->nomeAdquirente)
								row->addCell(iif(doc->modelo = &h2D, "2D", str(doc->modelo)))
								row->addCell("")
								row->addCell(doc->numero)
								row->addCell(YyyyMmDd2Datetime(doc->dataEmi))
								row->addCell(YyyyMmDd2Datetime(doc->dataEntSaida))
								row->addCell(doc->chave)
								row->addCell(codSituacao2Str(doc->situacao))
								row->addCell("")
								row->addCell(item->aliqICMS)
								row->addCell("")
								row->addCell("")
								row->addCell("")
								row->addCell("")
								row->addCell("")
								row->addCell(item->valor)
								row->addCell(item->numItem)
								row->addCell(item->qtd)
								row->addCell(item->unidade)
								row->addCell(item->cfop)
								row->addCell(item->cstICMS)
								var itemId = cast( TItemId ptr, itemIdDict->lookup(item->itemId) )
								if itemId <> null then 
									row->addCell(itemId->ncm)
									row->addCell(itemId->id)
									row->addCell(itemId->descricao)
								else
									row->addCell("")
									row->addCell("")
									row->addCell("")
								end if
								
								row->addCell("")
								row->addCell("")
							end if
						end if
					end if
				end if
				
			'SAT?
			case DOC_SAT
				if not opcoes->pularLrs then
					var doc = cast(TDocSAT ptr, reg)
					if ISREGULAR(doc->situacao) then
						'só existe cupom para saída
						if doc->operacao = SAIDA then
							var emitirLinha = (opcoes->somenteRessarcimentoST = false)
							if opcoes->filtrarCnpj andalso emitirLinha then
								emitirLinha = filtrarPorCnpj(doc->cpfCnpjAdquirente, opcoes->listaCnpj())
							end if
							
							if opcoes->filtrarChaves andalso emitirLinha then
								emitirLinha = filtrarPorChave(doc->chave, opcoes->listaChaves())
							end if
							
							if emitirLinha then
								dim as TDFe_NFeItem ptr item = null
								if itemNFeSafiFornecido and opcoes->acrescentarDados then
									var dfe = cast(TDFe_NFe ptr, chaveDFeDict->lookup(doc->chave))
									if dfe <> null then
										item = dfe->itemListHead
									end if
								end if
								
								var anal = iif(item = null, doc->itemAnalListHead, null)
								
								var analCnt = 1
								do
									var row = addRowSaidas()

									row->addCell(doc->cpfCnpjAdquirente)
									row->addCell("")
									row->addCell("SP")
									row->addCell("")
									row->addCell(str(doc->modelo))
									row->addCell("")
									row->addCell(doc->numero)
									row->addCell(YyyyMmDd2Datetime(doc->dataEmi))
									row->addCell(YyyyMmDd2Datetime(doc->dataEmi))
									row->addCell(doc->chave)
									row->addCell(codSituacao2Str(doc->situacao))
									if item <> null then
										row->addCell(item->bcICMS)
										row->addCell(item->aliqICMS)
										row->addCell(item->ICMS)
										row->addCell("")
										row->addCell("")
										row->addCell("")
										row->addCell("")
										row->addCell(item->valorProduto)
										row->addCell(item->nroItem)
										row->addCell(item->qtd)
										row->addCell(item->unidade)
										row->addCell(item->cfop)
										row->addCell(item->cst)
										row->addCell(item->ncm)
										row->addCell(item->codProduto)
										row->addCell(item->descricao)
										row->addCell("")
										row->addCell("")
										row->addCell("")
										row->addCell("")
										row->addCell("")
										
										item = item->next_
										if item = null then
											exit do
										end if
										
									else
										if anal = null then
											exit do
										end if
											
										row->addCell("")
										row->addCell(anal->aliq)
										row->addCell("")
										row->addCell("")
										row->addCell("")
										row->addCell("")
										row->addCell("")
										row->addCell(anal->valorOp)
										row->addCell(analCnt)
										row->addCell("")
										row->addCell("")
										row->addCell(anal->cfop)
										row->addCell(anal->cst)
										row->addCell("")
										row->addCell("")
										row->addCell("")
										row->addCell("")
										row->addCell("")
										row->addCell("")
										row->addCell("")
										row->addCell("")
										
										analCnt += 1
										anal = anal->next_
										if anal = null then
											exit do
										end if
									end if
								loop
							end if
						end if
					end if
				end if
				
			case APURACAO_ICMS_PERIODO
				if not opcoes->pularLraicms then
					var row = apuracaoIcms->AddRow()

					var apu = cast(TApuracaoIcmsPropPeriodo ptr, reg)
					row->addCell(YyyyMmDd2Datetime(apu->dataIni))
					row->addCell(YyyyMmDd2Datetime(apu->dataFim))
					row->addCell(apu->totalDebitos)
					row->addCell(apu->ajustesDebitos)
					row->addCell(apu->totalAjusteDeb)
					row->addCell(apu->estornosCredito)
					row->addCell(apu->totalCreditos)
					row->addCell(apu->ajustesCreditos)
					row->addCell(apu->totalAjusteCred)
					row->addCell(apu->estornoDebitos)
					row->addCell(apu->saldoCredAnterior)
					row->addCell(apu->saldoDevedorApurado)
					row->addCell(apu->totalDeducoes)
					row->addCell(apu->icmsRecolher)
					row->addCell(apu->saldoCredTransportar)
					row->addCell(apu->debExtraApuracao)
					
					var detalhe = ""
					var ajuste = apu->ajustesListHead
					var cnt = 1
					do while ajuste <> null andalso cnt <= MAX_AJUSTES
						row->addCell("{'codigo':'" & ajuste->codigo & "', 'valor':'" & DBL2MONEYBR(ajuste->valor) & "', 'descricao':'" & ajuste->descricao) & "'}"
						ajuste = ajuste->next_
						cnt += 1
					loop
					
					do while cnt <= MAX_AJUSTES
						row->addCell("")
						cnt += 1
					loop
					
				end if
				
			case APURACAO_ICMS_ST_PERIODO
				if not opcoes->pularLraicms then
					var row = apuracaoIcmsST->AddRow()

					var apu = cast(TApuracaoIcmsSTPeriodo ptr, reg)
					row->addCell(YyyyMmDd2Datetime(apu->dataIni))
					row->addCell(YyyyMmDd2Datetime(apu->dataFim))
					row->addCell(apu->UF)
					row->addCell(iif(apu->mov=0, "N", "S"))
					row->addCell(apu->saldoCredAnterior)
					row->addCell(apu->devolMercadorias)
					row->addCell(apu->totalRessarciment)
					row->addCell(apu->totalOutrosCred)
					row->addCell(apu->ajustesCreditos)
					row->addCell(apu->totalRetencao)
					row->addCell(apu->totalOutrosDeb)
					row->addCell(apu->ajustesDebitos)
					row->addCell(apu->saldoAntesDed)
					row->addCell(apu->totalDeducoes)
					row->addCell(apu->icmsRecolher)
					row->addCell(apu->saldoCredTransportar)
					row->addCell(apu->debExtraApuracao)

					var detalhe = ""
					var ajuste = apu->ajustesListHead
					var cnt = 1
					do while ajuste <> null andalso cnt <= MAX_AJUSTES
						row->addCell("{'codigo':'" & ajuste->codigo & "', 'valor':'" & DBL2MONEYBR(ajuste->valor) & "', 'descricao':'" & ajuste->descricao) & "'}"
						ajuste = ajuste->next_
						cnt += 1
					loop
					
					do while cnt <= MAX_AJUSTES
						row->addCell("")
						cnt += 1
					loop
				end if


			case INVENTARIO_ITEM
				var row = inventario->AddRow()
				
				var item = cast(TInventarioItem ptr, reg)
				row->addCell(YyyyMmDd2Datetime(item->dataInventario))

				var itemId = cast( TItemId ptr, itemIdDict->lookup(item->itemId) )
				if itemId <> null then 
					row->addCell(itemId->id)
					row->addCell(itemId->ncm)
					row->addCell(itemId->tipoItem)
					row->addCell(tipoItem2Str(itemId->tipoItem))
					row->addCell(itemId->descricao)
				else
					row->addCell(item->itemId)
					row->addCell("")
					row->addCell("")
					row->addCell("")
					row->addCell("")
				end if
				
				row->addCell(item->unidade)
				row->addCell(item->qtd)
				row->addCell(item->valorUnitario)
				row->addCell(item->valorItem)
				row->addCell(item->indPropriedade)
				var part = cast( TParticipante ptr, participanteDict->lookup(item->idParticipante) )
				if part <> null then
					row->addCell(iif(len(part->cpf) > 0, part->cpf, part->cnpj))
				else
					row->addCell("")
				end if
				row->addCell(item->txtComplementar)
				row->addCell(item->codConta)
				row->addCell(item->valorItemIR)

			case CIAP_ITEM
				if not opcoes->pularCiap then
					var item = cast(TCiapItem ptr, reg)
					if item->docCnt = 0 then
						var row = ciap->AddRow()
						
						var pai = item->pai
						row->addCell(YyyyMmDd2Datetime(pai->dataIni))
						row->addCell(YyyyMmDd2Datetime(pai->dataFim))
						row->addCell(pai->valorTributExpSoma)
						row->addCell(pai->valorTotalSaidas)
						row->addCell(pai->indicePercSaidas)
						
						var bemCiap = cast( TBemCiap ptr, bemCiapDict->lookup(item->bemId) )
						if bemCiap <> null then 
							row->addCell(bemCiap->id)
							row->addCell(bemCiap->descricao)
						else
							row->addCell(item->bemId)
							row->addCell("")
						end if
						
						row->addCell(YyyyMmDd2Datetime(item->dataMov))
						row->addCell(item->tipoMov)
						row->addCell(item->valorIcms)
						row->addCell(item->valorIcmsSt)
						row->addCell(item->valorIcmsFrete)
						row->addCell(item->valorIcmsDifal)
						row->addCell(item->parcela)
						row->addCell(item->valorParcela)
						for i as integer = 1 to 9
							row->addCell("")
						next
					end if
				end if

			case CIAP_ITEM_DOC
				if not opcoes->pularCiap then
				
					var row = ciap->AddRow()
					
					var doc = cast(TCiapItemDoc ptr, reg)
					var pai = doc->pai
					var avo = pai->pai
					row->addCell(YyyyMmDd2Datetime(avo->dataIni))
					row->addCell(YyyyMmDd2Datetime(avo->dataFim))
					row->addCell(avo->valorTributExpSoma)
					row->addCell(avo->valorTotalSaidas)
					row->addCell(avo->indicePercSaidas)
					
					var bemCiap = cast( TBemCiap ptr, bemCiapDict->lookup(pai->bemId) )
					if bemCiap <> null then 
						row->addCell(bemCiap->id)
						row->addCell(bemCiap->descricao)
					else
						row->addCell(pai->bemId)
						row->addCell("")
					end if
					
					row->addCell(YyyyMmDd2Datetime(pai->dataMov))
					row->addCell(pai->tipoMov)
					row->addCell(pai->valorIcms)
					row->addCell(pai->valorIcmsSt)
					row->addCell(pai->valorIcmsFrete)
					row->addCell(pai->valorIcmsDifal)
					row->addCell(pai->parcela)
					row->addCell(pai->valorParcela)
					
					row->addCell(doc->modelo)
					row->addCell(doc->serie)
					row->addCell(doc->numero)
					row->addCell(YyyyMmDd2Datetime(doc->dataEmi))
					row->addCell(doc->chaveNfe)
					
					var part = cast( TParticipante ptr, participanteDict->lookup(doc->idParticipante) )
					if part <> null then
						row->addCell(iif(len(part->cpf) > 0, part->cpf, part->cnpj))
						row->addCell(part->ie)
						row->addCell(MUNICIPIO2SIGLA(part->municip))
						row->addCell(part->nome)
					else
						row->addCell("")
						row->addCell("")
						row->addCell("")
						row->addCell("")
					end if
				end if

			case ESTOQUE_ITEM
				var row = estoque->AddRow()
				
				var item = cast(TEstoqueItem ptr, reg)
				var pai = item->pai
				row->addCell(YyyyMmDd2Datetime(pai->dataIni))
				row->addCell(YyyyMmDd2Datetime(pai->dataFim))
				
				var itemId = cast( TItemId ptr, itemIdDict->lookup(item->itemId) )
				if itemId <> null then 
					row->addCell(itemId->id)
					row->addCell(itemId->ncm)
					row->addCell(itemId->tipoItem)
					row->addCell(tipoItem2Str(itemId->tipoItem))
					row->addCell(itemId->descricao)
				else
					row->addCell(item->itemId)
					row->addCell("")
					row->addCell("")
					row->addCell("")
					row->addCell("")
				end if
				
				row->addCell(item->qtd)
				row->addCell(item->tipoEst)

				var part = cast( TParticipante ptr, participanteDict->lookup(item->idParticipante) )
				if part <> null then
					row->addCell(iif(len(part->cpf) > 0, part->cpf, part->cnpj))
					row->addCell(part->ie)
					row->addCell(MUNICIPIO2SIGLA(part->municip))
					row->addCell(part->nome)
				else
					row->addCell("")
					row->addCell("")
					row->addCell("")
					row->addCell("")
				end if

			case ESTOQUE_ORDEM_PROD
				var row = producao->AddRow()
				
				var ord = cast(TEstoqueOrdemProd ptr, reg)
				row->addCell(YyyyMmDd2Datetime(ord->dataIni))
				row->addCell(YyyyMmDd2Datetime(ord->dataFim))
				
				var itemId = cast( TItemId ptr, itemIdDict->lookup(ord->itemId) )
				if itemId <> null then 
					row->addCell(itemId->id)
					row->addCell(itemId->ncm)
					row->addCell(itemId->tipoItem)
					row->addCell(tipoItem2Str(itemId->tipoItem))
					row->addCell(itemId->descricao)
				else
					row->addCell(ord->itemId)
					row->addCell("")
					row->addCell("")
					row->addCell("")
					row->addCell("")
				end if
				
				row->addCell(ord->qtd)
				row->addCell(ord->idOrdem)

			'item de documento do sintegra?
			case SINTEGRA_DOCUMENTO_ITEM
				if not opcoes->pularLrs then
					var item = cast(TDocumentoItemSintegra ptr, reg)
					var doc = item->doc
					
					dim as TableRow ptr row 
					if doc->operacao = SAIDA then
						row = addRowSaidas()
					else
						row = addRowEntradas()
					end if
					
					var itemId = cast( TItemId ptr, itemIdDict->lookup(item->codMercadoria) )
					  
					row->addCell(doc->cnpj)
					row->addCell(doc->ie)
					row->addCell(ufCod2Sigla(doc->uf))
					row->addCell("")
					row->addCell(doc->modelo)
					row->addCell(doc->serie)
					row->addCell(doc->numero)
					row->addCell(YyyyMmDd2Datetime(doc->dataEmi))
					row->addCell("")
					row->addCell("")
					row->addCell(codSituacao2Str(doc->situacao))
					row->addCell(item->bcICMS)
					row->addCell(item->aliqICMS)
					row->addCell(item->bcICMS * item->aliqICMS / 100)
					row->addCell(item->bcICMSST)
					row->addCell("")
					row->addCell("")
					row->addCell(item->valorIPI)
					row->addCell(item->valor)
					row->addCell(item->nroItem)
					row->addCell(item->qtd)
					if itemId <> null then 
						row->addCell(rtrim(itemId->unidInventario))
					else
						row->addCell("")
					end if
					row->addCell(item->cfop)
					row->addCell(item->cst)
					if itemId <> null then 
						row->addCell(itemId->ncm)
						row->addCell(rtrim(itemId->id))
						row->addCell(rtrim(itemId->descricao))
					else
						row->addCell("")
						row->addCell("")
						row->addCell("")
					end if

					if doc->operacao = SAIDA then
						row->addCell("")
						row->addCell("")
						row->addCell("")
					end if

					row->addCell("")
					row->addCell("")
				end if

			case LUA_CUSTOM
				
				var l = cast(TLuaReg ptr, reg)
				var luaFunc = cast(customLuaCb ptr, customLuaCbDict->lookup(l->tipo))->writer
				
				if luaFunc <> null then
					lua_getglobal(lua, luaFunc)
					lua_rawgeti(lua, LUA_REGISTRYINDEX, l->table)
					lua_call(lua, 1, 0)
				end if
			
			end select

			regCnt += 1
			if not onProgress(null, regCnt / nroRegs) then
				exit do
			end if
			
			reg = reg->prox
		loop
	catch
		onError(!"\r\nErro ao tratar o registro de tipo (" & reg->tipo & !") carregado na linha (" & reg->linha & !")\r\n")
	endtry
	
	onProgress(null, 1)
	
end sub

''''''''
sub EfdTabelaExport.finalizar()
	onProgress("Gravando planilha: " + nomeArquivo, 0)
	ew->Flush()
	ew->Close
end sub

