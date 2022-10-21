#include once "EfdPdfExport.bi"
#include once "libs/Dict.bi"
#include once "vbcompat.bi"
#include once "libs/SQLite.bi"
#include once "libs/trycatch.bi"

const PAGE_LEFT = 30
const PAGE_RIGHT = 813
const PAGE_TOP = 514
const PAGE_BOTTOM = 441.9
const ROW_SPACE_BEFORE = 3
const STROKE_WIDTH = 0.5
const ROW_HEIGHT = STROKE_WIDTH + 9.5 + STROKE_WIDTH + 0.5 	'' espa�o anterior, linha superior, conte�do, linha inferior, espa�o posterior
const ROW_HEIGHT_LG = ROW_HEIGHT + 5.5						'' linha larga (quando len(raz�oSocial) > MAX_NAME_LEN)
const ANAL_HEIGHT = STROKE_WIDTH + 9.5 						'' linha superior, conte�do, linha inferior
const LRS_OBS_HEADER_HEIGHT = ANAL_HEIGHT
const LRS_OBS_HEIGHT = 14.0
const LRS_OBS_AJUSTE_HEADER_HEIGHT = LRS_OBS_HEIGHT + ANAL_HEIGHT - 1.0
const LRS_OBS_AJUSTE_HEIGHT = ANAL_HEIGHT
const LRE_OBS_AJUSTE_HEADER_HEIGHT = LRS_OBS_AJUSTE_HEADER_HEIGHT - 3.5
const LRE_MAX_NAME_LEN = 31.25
const LRS_MAX_NAME_LEN = 34.50
const AJUSTE_MAX_DESC_LEN = 140
const RESUMO_AJUSTE_MAX_DESC_LEN = 70
const LRE_RESUMO_TITLE_HEIGHT = 9
const LRE_RESUMO_HEADER_HEIGHT = 10
const LRE_RESUMO_ROW_HEIGHT = 10.0
const LRS_RESUMO_TITLE_HEIGHT = 9.0
const LRS_RESUMO_HEADER_HEIGHT = 9.0
const LRS_RESUMO_ROW_HEIGHT = 12.0
const CIAP_APUR_HEIGHT = 124
const CIAP_BEM_PRINC_HEIGHT = 47
const CIAP_BEM_HEIGHT = 180 - CIAP_BEM_PRINC_HEIGHT
const CIAP_DOC_HEIGHT = 82
const CIAP_DOC_ITEM_HEIGHT = 57
const CIAP_PAGE_BOTTOM = 480
const LRAICMS_FORM_HEIGHT = 240
const LRAICMS_PAGE_BOTTOM = 620
const LRAICMSST_FORM_HEIGHT = LRAICMS_FORM_HEIGHT + 10
const LRAICMS_AJ_DECOD_HEIGHT = 42
const LRAICMS_AJ_TITLE_HEIGHT = 18
const LRAICMS_AJ_HEADER_HEIGHT = 14
const LRAICMS_AJ_ROW_HEIGHT = 17
const LRAICMS_AJ_TOTAL_HEIGHT = 21
const LRAICMS_AJ_SUBTOTAL_HEIGHT = 17
const LRAICMS_AJ_DESC_MAX_LEN = 60

type TMovimento
	mov as zstring * 2+1
	descricao as wstring * 64+1
end type

type AjusteApuracao
	codigo as zstring * 8+1
	ajuste as TApuracaoIcmsAjuste ptr
end type

	dim shared movLut(0 to ...) as TMovimento = { _
		("SI", "Saldo inicial de bens imobilizados"), _
		("IM", "Imobilização de bem individual"), _
		("IA", "Imobilização em Andamento - Componente"), _
		("CI", "Conclusão de Imobilização em Andamento �?? Bem Resultante"), _
		("MC", "Imobilização oriunda do Ativo Circulante"), _
		("BA", "Baixa do bem - Fim do período de apropriação"), _
		("AT", "Alienação ou Transferência"), _
		("PE", "Perecimento, Extravio ou Deterioração"), _
		("OT", "Outras Saídas do Imobilizado") _
	}
	
	dim shared ajusteTipoToDecod(0 to 5) as zstring * 32+1 = { _
		"Outros débitos", _
		"Estorno de créditos", _
		"Outros créditos", _
		"Estorno de débitos", _
		"Deduções do imposto apurado", _
		"Débitos Especiais" _
	}
	
	dim shared ajusteTipoToTitle(0 to 5) as zstring * 32+1 = { _
		"AJUSTES A D�BITO", _
		"ESTORNOS DE CR�DITOS", _
		"AJUSTES A CR�DITO", _
		"ESTORNOS DE D�BITOS", _
		"DEDU��ES DE IMPOSTO APURADO", _
		"D�BITOS ESPECIAIS" _
	}

''''''''
constructor EfdPdfExport(baseTemplatesDir as string, infAssinatura as InfoAssinatura ptr, opcoes as OpcoesExtracao ptr)
	this.baseTemplatesDir = baseTemplatesDir
	this.infAssinatura = infAssinatura
	this.opcoes = opcoes
end constructor

''''''''
destructor EfdPdfExport()
end destructor

''''''''
function EfdPdfExport.withDBs(configDb as SQLite ptr) as EfdPdfExport ptr
	this.configDb = configDb
	return @this
end function

''''''''
function EfdPdfExport.withCallbacks(onProgress as OnProgressCB, onError as OnErrorCB) as EfdPdfExport ptr
	this.onProgress = onProgress
	this.onError = onError
	return @this
end function

''''''''
function EfdPdfExport.withLua(lua as lua_State ptr, customLuaCbDict as TDict ptr) as EfdPdfExport ptr
	this.lua = lua
	this.customLuaCbDict = customLuaCbDict
	return @this
end function

''''''''
function EfdPdfExport.withFiltros( _
		filtrarPorCnpj as OnFilterByStrCB, _
		filtrarPorChave as OnFilterByStrCB _
	) as EfdPdfExport ptr
	this.filtrarPorCnpj = filtrarPorCnpj
	this.filtrarPorChave = filtrarPorChave
	return @this
end function

''''''''
function EfdPdfExport.withDicionarios( _
		participanteDict as TDict ptr, _
		itemIdDict as TDict ptr, _
		chaveDFeDict as TDict ptr, _
		infoComplDict as TDict ptr, _
		obsLancamentoDict as TDict ptr, _
		bemCiapDict as TDict ptr, _
		contaContabDict as TDict ptr, _
		centroCustoDict as TDict ptr, _
		municipDict as TDict ptr _
	) as EfdPdfExport ptr
	this.participanteDict = participanteDict
	this.itemIdDict = itemIdDict
	this.chaveDFeDict = chaveDFeDict
	this.infoComplDict = infoComplDict
	this.obsLancamentoDict = obsLancamentoDict
	this.bemCiapDict = bemCiapDict
	this.contaContabDict = contaContabDict
	this.centroCustoDict = centroCustoDict
	this.municipDict = municipDict
	return @this
end function

''''''''
sub EfdPdfExport.gerar(regListHead as TRegistro ptr, regMestre as TMestre ptr, nroRegs as integer)
	
	if opcoes->somenteRessarcimentoST then
		onError(!"\tN�o ser� possivel gerar relat�rios porque s� foram extra�dos os registros com ressarcimento ST")
	end if
	
	this.regMestre = regMestre
	
	ultimoRelatorio = -1

	relLinhasList = new TList(cint(PAGE_BOTTOM / ROW_HEIGHT + 0.5), len(RelLinha), false)
	
	if not opcoes->pularLre then
		onProgress(!"\tGerando relat�rio do LRE", 0)

		'' LRE (contagem de p�ginas)
		iniciarRelatorio(REL_LRE, "entradas", "LRE", true)
		relNroTotalPaginas = 0
		
		var reg = regListHead
		var regCnt = 0
		var ultCompletado = 0.0
		try
			do while reg <> null
				select case as const reg->tipo
				'NF-e?
				case DOC_NF, DOC_NFSCT, DOC_NF_ELETRIC
					var nf = cast(TDocNF ptr, reg)
					if nf->operacao = ENTRADA then
						var part = cast( TParticipante ptr, participanteDict->lookup(nf->idParticipante) )
						list_add_DF_ENTRADA(nf, part, true)
					end if
				
				'CT-e?
				case DOC_CT
					var ct = cast(TDocCT ptr, reg)
					if ct->operacao = ENTRADA then
						var part = cast( TParticipante ptr, participanteDict->lookup(ct->idParticipante) )
						list_add_DF_ENTRADA(ct, part, true)
					end if
				end select
				
				regCnt += 1
				var completado = (regCnt / nroRegs) * 0.10
				if completado - ultCompletado >= 0.01 then
					ultCompletado = completado
					if not onProgress(null, completado) then
						exit do
					end if
				end if
				
				reg = reg->prox
			loop
		catch
			onError(!"\r\nErro ao tratar o registro de tipo (" & reg->tipo & !") carregado na linha (" & reg->linha & !")\r\n")
		endtry

		var totalRegs = nroRegistrosRel
		
		finalizarRelatorio(true)
		
		'' LRE (gera��o de p�ginas)
		iniciarRelatorio(REL_LRE, "entradas", "LRE", false)
		
		reg = regListHead
		ultCompletado = 0.0
		try
			'para cada registro..
			do while reg <> null
				select case as const reg->tipo
				'NF-e?
				case DOC_NF, DOC_NFSCT, DOC_NF_ELETRIC
					var nf = cast(TDocNF ptr, reg)
					if nf->operacao = ENTRADA then
						var part = cast( TParticipante ptr, participanteDict->lookup(nf->idParticipante) )
						list_add_DF_ENTRADA(nf, part, false)
					end if
				
				'CT-e?
				case DOC_CT
					var ct = cast(TDocCT ptr, reg)
					if ct->operacao = ENTRADA then
						var part = cast( TParticipante ptr, participanteDict->lookup(ct->idParticipante) )
						list_add_DF_ENTRADA(ct, part, false)
					end if

				case LUA_CUSTOM
					var l = cast(TLuaReg ptr, reg)
					var luaFunc = cast(customLuaCb ptr, customLuaCbDict->lookup(l->tipo))->rel_entradas
					
					if luaFunc <> null then
						'lua_getglobal(lua, luaFunc)
						'lua_pushlightuserdata(lua, dfwd)
						'lua_rawgeti(lua, LUA_REGISTRYINDEX, l->table)
						'lua_call(lua, 2, 0)
					end if
				end select
				
				var completado = 0.10 + (nroRegistrosRel / totalRegs) * 0.90
				if completado - ultCompletado >= 0.01 then
					ultCompletado = completado
					if not onProgress(null, completado) then
						exit do
					end if
				end if
				
				reg = reg->prox
			loop
		catch
			onError(!"\r\nErro ao tratar o registro de tipo (" & reg->tipo & !") carregado na linha (" & reg->linha & !")\r\n")
		endtry
		
		finalizarRelatorio(false)
		
		onProgress(null, 1)
	end if
	
	if not opcoes->pularLrs then
		onProgress(!"\tGerando relat�rio do LRS", 0)

		'' LRS (contagem de p�ginas)
		iniciarRelatorio(REL_LRS, "saidas", "LRS", true)
		relNroTotalPaginas = 0
		
		var reg = regListHead
		var regCnt = 0
		var ultCompletado = 0.0
		try
			do while reg <> null
				select case as const reg->tipo
				'NF-e?
				case DOC_NF, DOC_NFSCT, DOC_NF_ELETRIC
					var nf = cast(TDocNF ptr, reg)
					if nf->operacao = SAIDA then
						var part = cast( TParticipante ptr, participanteDict->lookup(nf->idParticipante) )
						list_add_DF_SAIDA(nf, part, true)
					end if

				'CT-e?
				case DOC_CT
					var ct = cast(TDocCT ptr, reg)
					if ct->operacao = SAIDA then
						var part = cast( TParticipante ptr, participanteDict->lookup(ct->idParticipante) )
						list_add_DF_SAIDA(ct, part, true)
					end if
					
				'ECF Redu��o Z?
				case ECF_REDUCAO_Z
					var redz = cast(TECFReducaoZ ptr, reg)
					list_add_REDZ(redz, true)
				
				'SAT?
				case DOC_SAT
					var sat = cast(TDocSAT ptr, reg)
					list_add_SAT(sat, true)
				end select

				regCnt += 1
				var completado = (regCnt / nroRegs) * 0.10
				if completado - ultCompletado >= 0.01 then
					ultCompletado = completado
					if not onProgress(null, completado) then
						exit do
					end if
				end if
				
				reg = reg->prox
			loop
		catch
			onError(!"\r\nErro ao tratar o registro de tipo (" & reg->tipo & !") carregado na linha (" & reg->linha & !")\r\n")
		endtry
		
		var totalRegs = nroRegistrosRel
		
		finalizarRelatorio(true)
		
		'' LRS (gera��o de p�ginas)
		iniciarRelatorio(REL_LRS, "saidas", "LRS", false)
		
		reg = regListHead
		ultCompletado = 0.0
		try
			do while reg <> null
				select case as const reg->tipo
				'NF-e?
				case DOC_NF, DOC_NFSCT, DOC_NF_ELETRIC
					var nf = cast(TDocNF ptr, reg)
					if nf->operacao = SAIDA then
						var part = cast( TParticipante ptr, participanteDict->lookup(nf->idParticipante) )
						list_add_DF_SAIDA(nf, part, false)
					end if

				'CT-e?
				case DOC_CT
					var ct = cast(TDocCT ptr, reg)
					if ct->operacao = SAIDA then
						var part = cast( TParticipante ptr, participanteDict->lookup(ct->idParticipante) )
						list_add_DF_SAIDA(ct, part, false)
					end if
					
				'ECF Redu��o Z?
				case ECF_REDUCAO_Z
					var redz = cast(TECFReducaoZ ptr, reg)
					list_add_REDZ(redz, false)
				
				'SAT?
				case DOC_SAT
					var sat = cast(TDocSAT ptr, reg)
					list_add_SAT(sat, false)
				
				case LUA_CUSTOM
					var l = cast(TLuaReg ptr, reg)
					var luaFunc = cast(customLuaCb ptr, customLuaCbDict->lookup(l->tipo))->rel_saidas
					
					if luaFunc <> null then
						'lua_getglobal(lua, luaFunc)
						'lua_pushlightuserdata(lua, dfwd)
						'lua_rawgeti(lua, LUA_REGISTRYINDEX, l->table)
						'lua_call(lua, 2, 0)
					end if
				end select

				var completado = 0.10 + (nroRegistrosRel / totalRegs) * 0.90
				if completado - ultCompletado >= 0.01 then
					ultCompletado = completado
					if not onProgress(null, completado) then
						exit do
					end if
				end if
				
				reg = reg->prox
			loop
		catch
			onError(!"\r\nErro ao tratar o registro de tipo (" & reg->tipo & !") carregado na linha (" & reg->linha & !")\r\n")
		endtry
		
		finalizarRelatorio(false)
		
		onProgress(null, 1)
	end if
	
	'' outros livros..
	var reg = regListHead
	try
		var ciapRegs = 0
		do while reg <> null
			'para cada registro..
			select case as const reg->tipo
			case APURACAO_ICMS_PERIODO
				if not opcoes->pularLraicms then
					onProgress(!"\tGerando relat�rio do LRAICMS", 0)
					var apu = cast(TApuracaoIcmsPropPeriodo ptr, reg)
					gerarRelatorioApuracaoICMS(apu, true)
					gerarRelatorioApuracaoICMS(apu, false)
					onProgress(null, 1)
				end if

			case APURACAO_ICMS_ST_PERIODO
				if not opcoes->pularLraicms then
					onProgress(!"\tGerando relat�rio do LRAICMS-ST", 0)
					var apu = cast(TApuracaoIcmsSTPeriodo ptr, reg)
					gerarRelatorioApuracaoICMSST(apu, true)
					gerarRelatorioApuracaoICMSST(apu, false)
					onProgress(null, 1)
				end if
				
			case CIAP_TOTAL
				ciapRegs += 1
				if not opcoes->pularCiap then
					onProgress(!"\tGerando relat�rio do CIAP", 0)
					var ciap = cast(TCiapTotal ptr, reg)
					gerarRelatorioCiap(ciap, true)
					gerarRelatorioCiap(ciap, false)
					onProgress(null, 1)
				end if
				
			case LUA_CUSTOM
				var l = cast(TLuaReg ptr, reg)
				var luaFunc = cast(customLuaCb ptr, customLuaCbDict->lookup(l->tipo))->rel_outros
				
				if luaFunc <> null then
					'lua_getglobal(lua, luaFunc)
					'lua_pushlightuserdata(lua, dfwd)
					'lua_rawgeti(lua, LUA_REGISTRYINDEX, l->table)
					'lua_call(lua, 2, 0)
				end if
			end select

			reg = reg->prox
		loop
		
		if not opcoes->pularCiap andalso ciapRegs = 0 then
			gerarRelatorioCiap(null, true)
			gerarRelatorioCiap(null, false)
		end if

	catch
		onError(!"\r\nErro ao tratar o registro de tipo (" & reg->tipo & !") carregado na linha (" & reg->linha & !")\r\n")
	endtry
	
	delete relLinhasList
	
end sub

''''''''
sub EfdPdfExport.iniciarRelatorio(relatorio as TipoRelatorio, nomeRelatorio as string, sufixo as string, isPre as boolean)

	if ultimoRelatorio = relatorio then
		return
	end if
		
	ultimoRelatorioSufixo = sufixo
	ultimoRelatorio = relatorio
	nroRegistrosRel = 0
	
	relYPos = 0
	relNroLinhas = 0
	relNroPaginas = 0
	relPage = null
	
	select case relatorio
	case REL_LRE, REL_LRS
		relSomaAnalList = new Tlist(10, len(RelSomatorioAnal))
		relSomaAnalDict = new TDict(10)
		relSomaAjustesList = new Tlist(10, len(RelSomatorioAjuste))
		relSomaAjustesDict = new TDict(10)
	end select

	if not isPre then
		relOutFile = new PdfDoc()

		relTemplate = new PdfTemplate(baseTemplatesDir + nomeRelatorio + ".xml")
		relTemplate->load()
		
		var page = relTemplate->getPage(0)
		
		'' alterar header e footer
		var header = page->getNode("header")
		header->setAttrib("hidden", false)
		
		setNodeText(page, "NOME", regMestre->nome, true)
		setNodeText(page, "CNPJ", STR2CNPJ(regMestre->cnpj))
		setNodeText(page, "IE", regMestre->ie)
		
		select case relatorio
		case REL_LRE, REL_LRS, REL_CIAP
			setNodeText(page, "UF", MUNICIPIO2SIGLA(regMestre->municip))
			setNodeText(page, "MUNICIPIO", codMunicipio2Nome(regMestre->municip, municipDict, configDb))
			if relatorio <> REL_CIAP then
				setNodeText(page, "APU", YyyyMmDd2DatetimeBR(regMestre->dataIni) + " a " + YyyyMmDd2DatetimeBR(regMestre->dataFim))
			else
				setNodeText(page, "ESCRIT", YyyyMmDd2DatetimeBR(regMestre->dataIni) + " a " + YyyyMmDd2DatetimeBR(regMestre->dataFim))
			end if
		end select
		
		var footer = page->getNode("footer")
		footer->setAttrib("hidden", false)
			
		if relatorio <> REL_CIAP then
			if infAssinatura <> null then
				setNodeText(page, "NOME_ASS", infAssinatura->assinante, true)
				setNodeText(page, "CPF_ASS", STR2CPF(infAssinatura->cpf))
				setNodeText(page, "HASH_ASS", infAssinatura->hashDoArquivo)
				if relatorio = REL_LRE then
					setNodeText(page, "NOME2_ASS", infAssinatura->assinante, true)
				end if
			end if
		end if
	end if

end sub

''''''''
sub EfdPdfExport.criarPaginaRelatorio(emitir as boolean, isPre as boolean)
	
	if not isPre then
		if emitir then
			if relPage <> null then
				emitirPaginaRelatorio(emitir, isPre)
			end if
			relPage = relTemplate->clonePage(0)
		end if
	end if

	relNroLinhas = 0
	relYPos = 0
	
	relNroPaginas += 1
	if relNroPaginas > relNroTotalPaginas then
		relNroTotalPaginas = relNroPaginas
	end if
	
end sub

sub EfdPdfExport.emitirPaginaRelatorio(emitir as boolean, isPre as boolean)
	if not isPre then
		if emitir then
			if relPage <> null then
				var pg = relPage->getNode("PAGINA")
				if pg <> null then
					pg->setAttrib("text", wstr(relNroPaginas & "de " & relNroTotalPaginas))
				end if
				relPage->render(relOutFile, relNroPaginas-1)
				delete relPage
				relPage = null
			end if
		end if
	end if
end sub

sub EfdPdfExport.list_add_ANAL(doc as TDocDF ptr, sit as TipoSituacao, isPre as boolean)
	var anal = doc->itemAnalListHead
	do while anal <> null
		if relYPos + ANAL_HEIGHT > PAGE_BOTTOM then
			gerarPaginaRelatorio(false, isPre)
		end if
		if not isPre then
			var lin = cast(RelLinha ptr, relLinhasList->add())
			lin->tipo = REL_LIN_DF_ITEM_ANAL
			lin->anal.item = anal
			lin->anal.sit = sit
		end if
		relYPos += ANAL_HEIGHT
		relNroLinhas += 1
		relatorioSomarAnal(sit, anal, isPre)
		anal = anal->next_
	loop
end sub

#define calcObsAjusteHeight(isFirst) (iif(isFirst, STROKE_WIDTH*2 + iif(ultimoRelatorio = REL_LRS, LRS_OBS_AJUSTE_HEADER_HEIGHT, LRE_OBS_AJUSTE_HEADER_HEIGHT), 0) + LRS_OBS_AJUSTE_HEIGHT)

sub EfdPdfExport.list_add_OBS_AJUSTE(obs as TDocObs ptr, sit as TipoSituacao, isPre as boolean)
	var cnt = 0
	var ajuste = obs->ajusteListHead
	do while ajuste <> null
		var height_ = calcObsAjusteHeight(cnt = 0)
		if relYPos + height_ > PAGE_BOTTOM then
			gerarPaginaRelatorio(false, isPre)
			height_ = calcObsAjusteHeight(true)
			cnt = 0
		end if
		if not isPre then
			var lin = cast(RelLinha ptr, relLinhasList->add())
			lin->tipo = REL_LIN_DF_OBS_AJUSTE
			lin->ajuste.ajuste = ajuste
			lin->ajuste.sit = sit
			lin->ajuste.isFirst = (cnt = 0)
		end if
		relYPos += height_
		relNroLinhas += 1
		cnt += 1
		relatorioSomarAjuste(sit, ajuste)
		ajuste = ajuste->next_
	loop
end sub

sub EfdPdfExport.list_add_OBS(doc as TDocDF ptr, sit as TipoSituacao, isPre as boolean)
	var cnt = 0
	var obs = doc->obsListHead
	do while obs <> null
		var height_ = calcObsHeight(sit, obs, cnt = 0)
		if relYPos + height_ > PAGE_BOTTOM then
			gerarPaginaRelatorio(false, isPre)
			height_ = calcObsHeight(sit, obs, true)
			cnt = 0
		end if
		if not isPre then
			var lin = cast(RelLinha ptr, relLinhasList->add())
			lin->tipo = REL_LIN_DF_OBS
			lin->obs.obs = obs
			lin->obs.sit = sit
			lin->obs.isFirst = (cnt = 0)
		end if
		relYPos += height_
		relNroLinhas += 1
		list_add_OBS_AJUSTE(obs, sit, isPre)
		cnt += 1
		obs = obs->next_
	loop
end sub

#define calcHeight(lg) iif(relNroLinhas > 0, ROW_SPACE_BEFORE, 0) + iif(lg, ROW_HEIGHT_LG, ROW_HEIGHT)

sub EfdPdfExport.list_add_DF_ENTRADA(doc as TDocDF ptr, part as TParticipante ptr, isPre as boolean)
	var len_ = iif(part <> null, ttfLen(part->nome), 0)
	var lg = len_ > cint(LRE_MAX_NAME_LEN + 0.5)
	var height_ = calcHeight(lg)
	if relYPos + height_ > PAGE_BOTTOM then
		gerarPaginaRelatorio(false, isPre)
		height_ = calcHeight(lg)
	end if
	if not isPre then
		var lin = cast(RelLinha ptr, relLinhasList->add())
		lin->tipo = REL_LIN_DF_ENTRADA
		lin->highlight = false
		lin->large = lg
		lin->df.doc = doc
		lin->df.part = part
	end if
	relYPos += height_
	relNroLinhas += 1
	nroRegistrosRel += 1
	list_add_ANAL(doc, doc->situacao, isPre)
	list_add_OBS(doc, doc->situacao, isPre)
end sub

sub EfdPdfExport.list_add_DF_SAIDA(doc as TDocDF ptr, part as TParticipante ptr, isPre as boolean)
	var len_ = iif(part <> null, ttfLen(part->nome), 0)
	var lg = len_ > cint(LRS_MAX_NAME_LEN + 0.5)
	var height_ = calcHeight(lg)
	if relYPos + height_ > PAGE_BOTTOM then
		gerarPaginaRelatorio(false, isPre)
		height_ = calcHeight(lg)
	end if
	if not isPre then
		var lin = cast(RelLinha ptr, relLinhasList->add())
		lin->tipo = REL_LIN_DF_SAIDA
		lin->highlight = false
		lin->large = lg
		lin->df.doc = doc
		lin->df.part = part
	end if
	relYPos += height_
	relNroLinhas += 1
	nroRegistrosRel += 1
	list_add_ANAL(doc, doc->situacao, isPre)
	list_add_OBS(doc, doc->situacao, isPre)
end sub

sub EfdPdfExport.list_add_REDZ(doc as TECFReducaoZ ptr, isPre as boolean)
	var height_ = calcHeight(false)
	if relYPos + height_ > PAGE_BOTTOM then
		gerarPaginaRelatorio(false, isPre)
		height_ = calcHeight(false)
	end if
	if not isPre then
		var lin = cast(RelLinha ptr, relLinhasList->add())
		lin->tipo = REL_LIN_DF_REDZ
		lin->highlight = false
		lin->large = false
		lin->redz.doc = doc
	end if
	relYPos += height_
	relNroLinhas += 1
	nroRegistrosRel += 1
	list_add_ANAL(doc, REGULAR, isPre)
end sub

sub EfdPdfExport.list_add_SAT(doc as TDocSAT ptr, isPre as boolean)
	var height_ = calcHeight(false)
	if relYPos + height_ > PAGE_BOTTOM then
		gerarPaginaRelatorio(false, isPre)
		height_ = calcHeight(false)
	end if
	if not isPre then
		var lin = cast(RelLinha ptr, relLinhasList->add())
		lin->tipo = REL_LIN_DF_SAT
		lin->highlight = false
		lin->large = false
		lin->sat.doc = doc
	end if
	relYPos += height_
	relNroLinhas += 1
	nroRegistrosRel += 1
	list_add_ANAL(doc, REGULAR, isPre)
	list_add_OBS(doc, REGULAR, isPre)
end sub

''''''''
function EfdPdfExport.gerarPaginaRelatorio(isLast as boolean, isPre as boolean) as boolean

	var gerar_ = true
	
	if not isPre then
		if opcoes->filtrarCnpj then
			gerar_ = false
			var n = cast(RelLinha ptr, relLinhasList->head)
			do while n <> null
				dim as TParticipante ptr part = null
				select case as const n->tipo
				case REL_LIN_DF_ENTRADA
					part = n->df.part
				case REL_LIN_DF_SAIDA
					part = n->df.part
				end select
				
				if part <> null then
					if filtrarPorCnpj(part->cnpj, opcoes->listaCnpj()) then
						gerar_ = true
						if not opcoes->highlight then
							exit do
						end if
						n->highlight = true
					end if
				end if
				
				n = relLinhasList->next_(n)
			loop
		end if
		
		if gerar_ andalso opcoes->filtrarChaves then
			gerar_ = false
			var n = cast(RelLinha ptr, relLinhasList->head)
			do while n <> null
				dim as zstring ptr chave = null
				select case as const n->tipo
				case REL_LIN_DF_ENTRADA, _
					 REL_LIN_DF_SAIDA
					chave = @n->df.doc->chave
				case REL_LIN_DF_SAT
					chave = @n->sat.doc->chave
				end select
				
				if chave <> null then
					if filtrarPorChave(chave, opcoes->listaChaves()) then
						gerar_ = true
						if not opcoes->highlight then
							exit do
						end if
						n->highlight = true
					end if
				end if
				
				n = relLinhasList->next_(n)
			loop
		end if
	end if

	var lastNroLinhas = relNroLinhas
	var lastYPos = relYPos
	criarPaginaRelatorio(gerar_, isPre)

	if not isPre then
		var n = cast(RelLinha ptr, relLinhasList->head)
		do while n <> null
			
			if gerar_ then
				select case as const n->tipo
				case REL_LIN_DF_ENTRADA
					adicionarDocRelatorioEntradas(n->df.doc, n->df.part, n->highlight, n->large)
				case REL_LIN_DF_SAIDA
					adicionarDocRelatorioSaidas(n->df.doc, n->df.part, n->highlight, n->large)
				case REL_LIN_DF_REDZ
					adicionarDocRelatorioSaidas(n->redz.doc, n->highlight)
				case REL_LIN_DF_SAT
					adicionarDocRelatorioSaidas(n->sat.doc, n->highlight)
				case REL_LIN_DF_ITEM_ANAL
					adicionarDocRelatorioItemAnal(n->anal.sit, n->anal.item)
				case REL_LIN_DF_OBS
					adicionarDocRelatorioObs(n->obs.sit, n->obs.obs, n->obs.isFirst)
				case REL_LIN_DF_OBS_AJUSTE
					adicionarDocRelatorioObsAjuste(n->ajuste.sit, n->ajuste.ajuste, n->ajuste.isFirst)
				end select
			else
				if isLast then
					select case as const n->tipo
					case REL_LIN_DF_ENTRADA, REL_LIN_DF_SAIDA
						relYPos += ROW_SPACE_BEFORE + iif(n->large, ROW_HEIGHT_LG, ROW_HEIGHT)
					case REL_LIN_DF_REDZ, REL_LIN_DF_SAT
						relYPos += ROW_SPACE_BEFORE + ROW_HEIGHT
					case REL_LIN_DF_ITEM_ANAL
						relYPos += ANAL_HEIGHT
					case REL_LIN_DF_OBS
						relYPos += calcObsHeight(n->obs.sit, n->obs.obs, n->obs.isFirst)
					case REL_LIN_DF_OBS_AJUSTE
						relYPos += calcObsAjusteHeight(n->ajuste.isFirst)
					end select
				end if
			end if
			
			var p = n
			n = relLinhasList->next_(n)
			relLinhasList->del(p)
		loop
	else
		if isLast then
			relNroLinhas = lastNroLinhas
			relYPos = lastYPos
		end if
	end if
	
	if not isLast then
		emitirPaginaRelatorio(gerar_, isPre)
		relNroLinhas = 0
		relYPos = 0
	end if
	
	return gerar_

end function

private function movToDesc(mov as string) as string
	for i as integer = 0 to ubound(movLut)
		if movLut(i).mov = mov then
			return movLut(i).descricao
		end if
	next
	return ""
end function

''''''''
sub EfdPdfExport.setChildText(elm as PdfElement ptr, id as zstring ptr, value as wstring ptr)
	if value <> null andalso len(*value) > 0 then
		var node = elm->getChild(id)
		node->setAttrib("text", value)
	end if
end sub

''''''''
sub EfdPdfExport.setChildText(elm as PdfElement ptr, id as zstring ptr, value as string, convert as boolean)
	if len(value) > 0 then
		var node = elm->getChild(id)
		if not convert then
			node->setAttrib("text", value)
		else
			var utf16le = latinToUtf16le(value)
			if utf16le <> null then
				node->setAttrib("text", utf16le)
				deallocate utf16le
			end if
		end if
	end if
end sub

''''''''
sub EfdPdfExport.setNodeText(page as PdfPageElement ptr, id as zstring ptr, value as wstring ptr)
	if value <> null andalso len(*value) > 0 then
		var node = page->getNode(id)
		node->setAttrib("text", value)
	end if
end sub

''''''''
sub EfdPdfExport.setNodeText(page as PdfPageElement ptr, id as zstring ptr, value as string, convert as boolean)
	if len(value) > 0 then
		var node = page->getNode(id)
		if not convert then
			node->setAttrib("text", value)
		else
			var utf16le = latinToUtf16le(value)
			if utf16le <> null then
				node->setAttrib("text", utf16le)
				deallocate utf16le
			end if
		end if
	end if
end sub

''''''''
sub EfdPdfExport.gerarRelatorioCiap(reg as TCiapTotal ptr, isPre as boolean)

	iniciarRelatorio(REL_CIAP, "ciap", "CIAP", isPre)
	
	criarPaginaRelatorio(true, isPre)
	
	if reg <> null then
		if not isPre then
			var node = relPage->getNode("apur")
			var apur = node->clone(relPage, relPage)
			apur->setAttrib("hidden", false)
		
			setChildText(apur, "APU", YyyyMmDd2DatetimeBR(reg->dataIni) + " a " + YyyyMmDd2DatetimeBR(reg->dataFim))
			setChildText(apur, "SALDO", DBL2MONEYBR(reg->saldoInicialICMS))
			setChildText(apur, "SOMA_PARCELAS", DBL2MONEYBR(reg->parcelasSoma))
			setChildText(apur, "SOMA_SAIDAS_TRIB", DBL2MONEYBR(reg->valorTributExpSoma))
			setChildText(apur, "SOMA_SAIDAS", DBL2MONEYBR(reg->valorTotalSaidas))
			setChildText(apur, "INDICE", format(reg->indicePercSaidas, "#,#,0.00000000"))
			setChildText(apur, "CRED_ATIVO", DBL2MONEYBR(reg->valorIcmsAprop))
			setChildText(apur, "CRED_OUTROS", DBL2MONEYBR(reg->valorOutrosCred))
		end if
		
		relYPos += CIAP_APUR_HEIGHT + 6
		
		var item = reg->itemListHead
		do while item <> null
			if relYPos + CIAP_BEM_HEIGHT > CIAP_PAGE_BOTTOM then
				criarPaginaRelatorio(true, isPre)
			end if
			
			dim bemCiap as TBemCiap ptr = null
			
			if not isPre then
				var node = relPage->getNode("bem")
				var elm = node->clone(relPage, relPage)
				elm->setAttrib("hidden", false)
				elm->translateY(-relYPos)		
				setChildText(elm, "DATA_MOV", YyyyMmDd2DatetimeBR(item->dataMov))
				setChildText(elm, "TIPO_MOV", item->tipoMov & " - " & movToDesc(item->tipoMov))
				setChildText(elm, "COD_BEM", item->bemId)
				setChildText(elm, "CRED_PROP", DBL2MONEYBR(item->valorIcms))
				setChildText(elm, "CRED_ST", DBL2MONEYBR(item->valorIcmsST))
				setChildText(elm, "CRED_DIFAL", DBL2MONEYBR(item->valorIcmsDifal))
				setChildText(elm, "CRED_FRETE", DBL2MONEYBR(item->valorIcmsFrete))
				setChildText(elm, "PARCELA", str(item->parcela))
				setChildText(elm, "VAL_PARCELA", DBL2MONEYBR(item->valorParcela))

				bemCiap = cast( TBemCiap ptr, bemCiapDict->lookup(item->bemId) )
				if bemCiap <> null then 
					setChildText(elm, "ID_BEM", iif(bemCiap->tipoMerc = 1, "1 - bem", "2 - componente"))
					setChildText(elm, "DESC_BEM", bemCiap->descricao, true)
					setChildText(elm, "FUNC_BEM", bemCiap->funcao, true)
					setChildText(elm, "VIDA_UTIL", str(bemCiap->vidaUtil))
					setChildText(elm, "CONTA_ANAL", bemCiap->codAnal)
					var contaContab = cast( TContaContab ptr, contaContabDict->lookup(bemCiap->codAnal) )
					if contaContab <> null then
						setChildText(elm, "DESC_CONTA", contaContab->descricao, true)
					end if
					setChildText(elm, "COD_CUSTO", bemCiap->codCusto)
					var centroCusto = cast( TCentroCusto ptr, centroCustoDict->lookup(bemCiap->codCusto) )
					if centroCusto <> null then
						setChildText(elm, "DESC_CUSTO", centroCusto->descricao, true)
					end if
				end if
			end if
			
			relYPos += CIAP_BEM_HEIGHT
			if relYPos + CIAP_BEM_PRINC_HEIGHT > CIAP_PAGE_BOTTOM then
				criarPaginaRelatorio(true, isPre)
			end if

			if not isPre then
				var node = relPage->getNode("bem-princ")
				var elm = node->clone(relPage, relPage)
				elm->setAttrib("hidden", false)
				elm->translateY(-relYPos)		

				if bemCiap <> null then 
					if len(bemCiap->principal) > 0 then
						var princ = cast( TBemCiap ptr, bemCiapDict->lookup(bemCiap->principal) )
						if princ <> null then
							setChildText(elm, "COD_BEM_PRINC", bemCiap->principal)
							setChildText(elm, "DESC_BEM_PRINC", princ->descricao, true)
							setChildText(elm, "CONTA_BEM_PRINC", princ->codAnal)
							var contaContab = cast( TContaContab ptr, contaContabDict->lookup(princ->codAnal) )
							if contaContab <> null then
								setChildText(elm, "DESC_CONTA_BEM_PRINC", contaContab->descricao, true)
							end if
						end if
					end if
				end if
			end if

			relYPos += CIAP_BEM_PRINC_HEIGHT + 3
			
			var doc = item->docListHead
			do while doc <> null
				if relYPos + CIAP_DOC_HEIGHT > CIAP_PAGE_BOTTOM then
					criarPaginaRelatorio(true, isPre)
				end if

				if not isPre then
					var node = relPage->getNode("doc")
					var elm = node->clone(relPage, relPage)
					elm->setAttrib("hidden", false)
					elm->translateY(-relYPos)		

					setChildText(elm, "NUM", str(doc->numero))
					setChildText(elm, "MOD", format(doc->modelo, "00"))
					setChildText(elm, "CHAVE", doc->chaveNFe)
					setChildText(elm, "DTEMI", YyyyMmDd2DatetimeBR(doc->dataEmi))
					
					var part = cast( TParticipante ptr, participanteDict->lookup(doc->idParticipante) )
					if part <> null then
						setChildText(elm, "FORNEC_ID", doc->idParticipante)
						setChildText(elm, "FORNEC_NOME", part->nome, true)
					end if
				end if

				relYPos += CIAP_DOC_HEIGHT
				
				var itemDoc = doc->itemListHead
				do while itemDoc <> null
					if relYPos + CIAP_DOC_ITEM_HEIGHT > CIAP_PAGE_BOTTOM then
						criarPaginaRelatorio(true, isPre)
					end if

					if not isPre then
						var node = relPage->getNode("item")
						var elm = node->clone(relPage, relPage)
						elm->setAttrib("hidden", false)
						elm->translateY(-relYPos)

						setChildText(elm, "ITEM", str(itemDoc->num))
						var itemId = cast( TItemId ptr, itemIdDict->lookup(itemDoc->itemId) )
						if itemId <> null then 
							setChildText(elm, "ITEM_COD", itemId->id)
							setChildText(elm, "ITEM_DESC", itemId->descricao, true)
						else
							setChildText(elm, "ITEM_COD", itemDoc->itemId)
						end if
					end if

					relYPos += CIAP_DOC_ITEM_HEIGHT
				
					itemDoc = itemDoc->next_
				loop

				doc = doc->next_
			loop
			
			relYPos += 6
			
			if not isPre then
				var node = relPage->getNode("div")
				var elm = node->clone(relPage, relPage)
				elm->setAttrib("hidden", false)
				elm->translateY(-relYPos)
			end if

			relYPos += 2.5
			
			relYPos += 12
			
			item = item->next_
		loop
	
	else
		if not isPre then
			var empty = relPage->getNode("empty")
			empty->setAttrib("hidden", false)
		end if
	end if
	
	finalizarRelatorio(isPre)
	
end sub

''''''''
sub EfdPdfExport.gerarAjusteTotalRelatorioApuracaoICMS(tipo as integer, total as double, isPre as boolean, op as integer)
	if relYpos + LRAICMS_AJ_TOTAL_HEIGHT > LRAICMS_PAGE_BOTTOM then
		criarPaginaRelatorio(true, isPre)
	end if
	
	if not isPre then
		var node = relPage->getNode("ajuste-total")
		var clone = node->clone(relPage, relPage)
		clone->setAttrib("hidden", false)
		clone->translateY(-relYPos)
		setChildText(clone, "AJ-TOTAL-DESC", "VALOR TOTAL DOS " & ajusteTipoToTitle(tipo) & iif(op = 1, " ST", ""), true)
		setChildText(clone, "AJ-TOTAL-VAL", DBL2MONEYBR(total))
	end if
	
	relYpos += LRAICMS_AJ_TOTAL_HEIGHT
end sub

''''''''
sub EfdPdfExport.gerarAjusteSubTotalRelatorioApuracaoICMS(tipo as integer, codigo as string, subtotal as double, isPre as boolean)
	'' subtotal
	if relYpos + LRAICMS_AJ_SUBTOTAL_HEIGHT > LRAICMS_PAGE_BOTTOM then
		criarPaginaRelatorio(true, isPre)
	end if

	if not isPre then
		var node = relPage->getNode("ajuste-subtotal")
		var clone = node->clone(relPage, relPage)
		clone->setAttrib("hidden", false)
		clone->translateY(-relYPos)
		setChildText(clone, "AJ-SUB-DESC", "VALOR TOTAL DOS " & ajusteTipoToTitle(tipo) & "POR CODIGO: " & codigo, true)
		setChildText(clone, "AJ-SUB-VALOR", DBL2MONEYBR(subtotal))
	end if
	relYPos += LRAICMS_AJ_SUBTOTAL_HEIGHT
end sub


private function ajusteApuracaoCmpCb(key as zstring ptr, node as any ptr) as boolean
	function = *key < cast(AjusteApuracao ptr, node)->codigo
end function

''''''''
sub EfdPdfExport.gerarAjustesRelatorioApuracaoICMS(ajuste as TApuracaoIcmsAjuste ptr, isPre as boolean, opType as integer)
	if ajuste <> null then
	
		var ordered = new TList(10, len(AjusteApuracao))
		
		do while ajuste <> null
			var op = cint(mid(ajuste->codigo, 3, 1))
			if op = opType then
				var aj = cast(AjusteApuracao ptr, ordered->addOrdAsc(ajuste->codigo, @ajusteApuracaoCmpCb))
				aj->codigo = ajuste->codigo
				aj->ajuste = ajuste
			end if
			ajuste = ajuste->next_
		loop
		
		var ultimoTipo = -1
		var total = 0.0
		var ultimoCodigo = ""
		var subtotal = 0.0
		var cnt = 0
		
		var aj = cast(AjusteApuracao ptr, ordered->head)
		do while aj <> null
			ajuste = aj->ajuste
			
			if ultimoCodigo <> ajuste->codigo then
				if cnt > 0 then
					gerarAjusteSubTotalRelatorioApuracaoICMS(ultimoTipo, ultimoCodigo, subtotal, isPre)
				end if
				
				cnt = 0
				subtotal = ajuste->valor
			else
				cnt += 1
				subtotal += ajuste->valor
			end if
			
			var tipo = cint(mid(ajuste->codigo, 4, 1))
			if tipo <> ultimoTipo then
				'' total
				if ultimoTipo <> -1 then
					gerarAjusteTotalRelatorioApuracaoICMS(ultimoTipo, total, isPre, opType)
				end if
				
				'' decod
				relYpos += 7
					
				if relYpos + LRAICMS_AJ_DECOD_HEIGHT + LRAICMS_AJ_TITLE_HEIGHT > LRAICMS_PAGE_BOTTOM then
					criarPaginaRelatorio(true, isPre)
				end if
				
				if not isPre then
					var node = relPage->getNode("ajuste-decod")
					var clone = node->clone(relPage, relPage)
					clone->setAttrib("hidden", false)
					clone->translateY(-relYPos)
					setChildText(clone, "AJ-TIPO", tipo & " - " & ajusteTipoToDecod(tipo))
				end if
				relYPos += LRAICMS_AJ_DECOD_HEIGHT

				'' title
				if not isPre then
					var node = relPage->getNode("ajuste-title")
					var clone = node->clone(relPage, relPage)
					clone->setAttrib("hidden", false)
					clone->translateY(-relYPos)
					setChildText(clone, "AJ-TITLE", "DEMONSTRATIVO DO VALOR TOTAL DOS " & ajusteTipoToTitle(tipo) & iif(opType = 1, " ST", ""), true)
				end if
				relYPos += LRAICMS_AJ_TITLE_HEIGHT

				total = ajuste->valor
			else
				total += ajuste->valor
			end if
			
			if tipo <> ultimoTipo orelse relYpos + LRAICMS_AJ_HEADER_HEIGHT > LRAICMS_PAGE_BOTTOM then
				'' header
				if relYpos + LRAICMS_AJ_HEADER_HEIGHT > LRAICMS_PAGE_BOTTOM then
					criarPaginaRelatorio(true, isPre)
				end if
				
				if not isPre then
					var node = relPage->getNode("ajuste-header")
					var clone = node->clone(relPage, relPage)
					clone->setAttrib("hidden", false)
					clone->translateY(-relYPos)
				end if
				relYPos += LRAICMS_AJ_HEADER_HEIGHT
			end if
			
			var text = ajuste->codigo & " " & ajuste->descricao
			var textLen = ttfLen(text)
			var parts = cint(textLen / LRAICMS_AJ_DESC_MAX_LEN + 0.5)
				
			'' row
			if relYpos + LRAICMS_AJ_ROW_HEIGHT + (10.0 * (parts-1)) > LRAICMS_PAGE_BOTTOM then
				criarPaginaRelatorio(true, isPre)
			end if

			if not isPre then
				var node = relPage->getNode("ajuste-row")
				var row = node->clone(relPage, relPage)
				row->setAttrib("hidden", false)
				row->translateY(-relYPos)
				setChildText(row, "AJ-COD", ajuste->codigo)
				setChildText(row, "AJ-VALOR", DBL2MONEYBR(ajuste->valor))
				
				var desc = row->getChild("AJ-DESC")
				if parts > 1 then
					desc->getParent()->setAttrib("h", LRAICMS_AJ_ROW_HEIGHT + (10.0 * (parts-1)))
				end if
				
				var start = 0.0!
				for i as integer = 0 to parts-1
					var utf16le = latinToUtf16le(ttfSubstr(text, start, LRAICMS_AJ_DESC_MAX_LEN))
					desc->setAttrib("text", utf16le)
					deallocate utf16le
					if i < parts-1 then
						desc = desc->clone(desc->getParent(), relPage)
						desc->translateY(-10.0)
					end if
				next
				
			end if
			
			relYPos += LRAICMS_AJ_ROW_HEIGHT + (10.0 * (parts-1))
			
			ultimoTipo = tipo
			ultimoCodigo = ajuste->codigo
			
			aj = ordered->next_(aj)
		loop
		
		if cnt > 0 then
			gerarAjusteSubTotalRelatorioApuracaoICMS(ultimoTipo, ultimoCodigo, subtotal, isPre)
		end if
		
		gerarAjusteTotalRelatorioApuracaoICMS(ultimoTipo, total, isPre, opType)

		delete ordered
	end if
end sub

''''''''
sub EfdPdfExport.gerarRelatorioApuracaoICMS(reg as TApuracaoIcmsPropPeriodo ptr, isPre as boolean)

	iniciarRelatorio(REL_RAICMS, "apuracao_icms", "RAICMS", isPre)
	if isPre then
		relNroTotalPaginas = 0
	end if
	
	criarPaginaRelatorio(true, isPre)
	
	if not isPre then
		setNodeText(relPage, "ESCRIT", YyyyMmDd2DatetimeBR(regMestre->dataIni) + " a " + YyyyMmDd2DatetimeBR(regMestre->dataFim))
		
		var node = relPage->getNode("form")
		var clone = node->clone(relPage, relPage)
		clone->setAttrib("hidden", false)
	
		setChildText(clone, "APU", YyyyMmDd2DatetimeBR(reg->dataIni) + " a " + YyyyMmDd2DatetimeBR(reg->dataFim))
		setChildText(clone, "SAIDAS", DBL2MONEYBR(reg->totalDebitos))
		setChildText(clone, "AJUSTE_DEB", DBL2MONEYBR(reg->ajustesDebitos))
		setChildText(clone, "AJUSTE_DEB_IMP", DBL2MONEYBR(reg->totalAjusteDeb))
		setChildText(clone, "ESTORNO_CRED", DBL2MONEYBR(reg->estornosCredito))
		setChildText(clone, "CREDITO", DBL2MONEYBR(reg->totalCreditos))
		setChildText(clone, "AJUSTE_CRED", DBL2MONEYBR(reg->ajustesCreditos))
		setChildText(clone, "AJUSTE_CRED_IMP", DBL2MONEYBR(reg->totalAjusteCred))
		setChildText(clone, "ESTORNO_DEB", DBL2MONEYBR(reg->estornoDebitos))
		setChildText(clone, "CRED_ANTERIOR", DBL2MONEYBR(reg->saldoCredAnterior))
		setChildText(clone, "SALDO_DEV", DBL2MONEYBR(reg->saldoDevedorApurado))
		setChildText(clone, "DEDUCOES", DBL2MONEYBR(reg->totalDeducoes))
		setChildText(clone, "A_RECOLHER", DBL2MONEYBR(reg->icmsRecolher))
		setChildText(clone, "A_TRANSPORTAR", DBL2MONEYBR(reg->saldoCredTransportar))
		setChildText(clone, "EXTRA_APU", DBL2MONEYBR(reg->debExtraApuracao))
	end if
	relYPos += LRAICMS_FORM_HEIGHT
	
	gerarAjustesRelatorioApuracaoICMS(reg->ajustesListHead, isPre, 0)

	finalizarRelatorio(isPre)
	
end sub

''''''''
sub EfdPdfExport.gerarRelatorioApuracaoICMSST(reg as TApuracaoIcmsSTPeriodo ptr, isPre as boolean)

	iniciarRelatorio(REL_RAICMSST, "apuracao_icms_st", "RAICMSST_" + reg->UF, isPre)
	if isPre then
		relNroTotalPaginas = 0
	end if

	criarPaginaRelatorio(true, isPre)
	
	if not isPre then
		setNodeText(relPage, "ESCRIT", YyyyMmDd2DatetimeBR(regMestre->dataIni) + " a " + YyyyMmDd2DatetimeBR(regMestre->dataFim))

		var node = relPage->getNode("form")
		var clone = node->clone(relPage, relPage)
		clone->setAttrib("hidden", false)
	
		setChildText(clone, "APU", YyyyMmDd2DatetimeBR(reg->dataIni) + " a " + YyyyMmDd2DatetimeBR(reg->dataFim))
		setChildText(clone, "UF", reg->UF)
		setChildText(clone, "MOV", iif(reg->mov, "1 - COM", "0 - SEM"))
		
		setChildText(clone, "SALDO_CRED", DBL2MONEYBR(reg->saldoCredAnterior))
		setChildText(clone, "DEVOLUCOES", DBL2MONEYBR(reg->devolMercadorias))
		setChildText(clone, "RESSARCIMENTOS", DBL2MONEYBR(reg->totalRessarciment))
		setChildText(clone, "OUTROS_CRED", DBL2MONEYBR(reg->totalOutrosCred))
		setChildText(clone, "AJUSTE_CRED", DBL2MONEYBR(reg->ajustesCreditos))
		setChildText(clone, "ICMS_ST", DBL2MONEYBR(reg->totalRetencao))
		setChildText(clone, "OUTROS_DEB", DBL2MONEYBR(reg->totalOutrosDeb))
		setChildText(clone, "AJUSTE_DEB", DBL2MONEYBR(reg->ajustesDebitos))
		setChildText(clone, "SALDO_DEV", DBL2MONEYBR(reg->saldoAntesDed))
		setChildText(clone, "DEDUCOES", DBL2MONEYBR(reg->totalDeducoes))
		setChildText(clone, "A_RECOLHER", DBL2MONEYBR(reg->icmsRecolher))
		setChildText(clone, "A_TRANSPORTAR", DBL2MONEYBR(reg->saldoCredTransportar))
		setChildText(clone, "EXTRA_APU", DBL2MONEYBR(reg->debExtraApuracao))
	end if
	relYPos += LRAICMSST_FORM_HEIGHT
	
	gerarAjustesRelatorioApuracaoICMS(reg->ajustesListHead, isPre, 1)

	finalizarRelatorio(isPre)
	
end sub

''''''''
function EfdPdfExport.gerarLinhaDFe(lg as boolean, highlight as boolean) as PdfElement ptr
	if relNroLinhas > 0 then
		relYPos += ROW_SPACE_BEFORE
	end if
	
	var height = iif(lg, ROW_HEIGHT_LG, ROW_HEIGHT)
	
	if highlight then
		var hl = new PdfHighlightElement(PAGE_LEFT, (PAGE_TOP-relYpos-height), PAGE_RIGHT, (PAGE_TOP-relYPos), relPage)
	end if
	
	var row = relPage->getNode(iif(lg, "row-lg", "row"))
	var clone = row->clone(relPage, relPage)
	clone->setAttrib("hidden", false)
	clone->translateY(-relYPos)
	
	relYPos += height
	relNroLinhas += 1
	
	return clone
end function

''''''''
function EfdPdfExport.gerarLinhaAnal() as PdfElement ptr
	var anal = relPage->getNode("anal")
	var clone = anal->clone(relPage, relPage)
	clone->setAttrib("hidden", false)
	clone->translateY(-relYPos)
	
	relYPos += ANAL_HEIGHT
	relNroLinhas += 1

	return clone
end function

function EfdPdfExport.calcObsHeight(sit as TipoSituacao, obs as TDocObs ptr, isFirst as boolean) as double
	if not ISREGULAR(sit) then
		return 0.0
	end if
	
	var lanc = cast( TObsLancamento ptr, obsLancamentoDict->lookup(obs->idLanc))
	var text = iif(lanc <> null, lanc->descricao, "")
	if len(obs->extra) > 0 then
		text += " " + obs->extra
	end if
	var textLen = ttfLen(text)
	var parts = cint(textLen / AJUSTE_MAX_DESC_LEN + 0.5)

	return iif(isFirst, STROKE_WIDTH*2 + LRS_OBS_HEADER_HEIGHT, 0) + LRS_OBS_HEIGHT + ((parts-1) * 8.0)
end function

''''''''
function EfdPdfExport.gerarLinhaObs(isFirst as boolean, parts as integer) as PdfElement ptr

	if isFirst then
		var node = relPage->getNode("obs-header")
		var clone = node->clone(node->getParent(), relPage)
		clone->setAttrib("hidden", false)
		relYPos += STROKE_WIDTH*2
		clone->translateY(-relYPos)
		relYPos += LRS_OBS_HEADER_HEIGHT
	end if
	
	var node = relPage->getNode("obs")
	var row = node->clone(node->getParent(), relPage)
	row->setAttrib("hidden", false)
	row->translateY(-relYPos)
	relYPos += LRS_OBS_HEIGHT + ((parts-1) * 8.0)
	relNroLinhas += 1

	return row
end function

''''''''
function EfdPdfExport.gerarLinhaObsAjuste(isFirst as boolean) as PdfElement ptr

	if isFirst then
		var node = relPage->getNode("ajuste-header")
		var clone = node->clone(node->getParent(), relPage)
		clone->setAttrib("hidden", false)
		relYPos += STROKE_WIDTH*2
		clone->translateY(-relYPos)
		relYPos += iif(ultimoRelatorio = REL_LRS, LRS_OBS_AJUSTE_HEADER_HEIGHT, LRE_OBS_AJUSTE_HEADER_HEIGHT)
	end if
	
	var node = relPage->getNode("ajuste")
	var clone = node->clone(node->getParent(), relPage)
	clone->setAttrib("hidden", false)
	clone->translateY(-relYPos)
	relYPos += LRS_OBS_AJUSTE_HEIGHT
	relNroLinhas += 1

	return clone
end function

private function somaAnalCmpCb(key as zstring ptr, node as any ptr) as boolean
	function = *key < cast(RelSomatorioAnal ptr, node)->chave
end function

''''''''
sub EfdPdfExport.relatorioSomarAnal(sit as TipoSituacao, anal as TDocItemAnal ptr, isPre as boolean)
	
	dim as string chave = iif(ultimoRelatorio = REL_LRS, str(sit), "0")
	
	chave &= format(anal->cst,"000") & anal->cfop & format(anal->aliq, "00")
	
	var soma = cast(RelSomatorioAnal ptr, relSomaAnalDict->lookup(chave))
	if soma = null then
		soma = relSomaAnalList->addOrdAsc(strptr(chave), @somaAnalCmpCb)
		soma->chave = chave
		if not isPre then
			soma->situacao = sit
			soma->cst = anal->cst
			soma->cfop = anal->cfop
			soma->aliq = anal->aliq
		end if
		relSomaAnalDict->add(soma->chave, soma)
	end if
	
	if not isPre then	
		soma->valorOp += anal->valorOp
		soma->bc += anal->bc
		soma->icms += anal->icms
		soma->bcST += anal->bcST
		soma->icmsST += anal->icmsST
		soma->ipi += anal->ipi
	end if
end sub

private function somaAjustesCmpCb(key as zstring ptr, node as any ptr) as boolean
	function = *key < cast(RelSomatorioAjuste ptr, node)->chave
end function

''''''''
sub EfdPdfExport.relatorioSomarAjuste(sit as TipoSituacao, ajuste as TDocObsAjuste ptr)
	
	sit = 0 'BUG: o PVA RFB n�o faz a separa��o por situa��o, somando tudo e exibindo s� a situa��o 00, mesmo para NF's canceladas
	
	dim as string chave = iif(ultimoRelatorio = REL_LRS, str(sit), "0") & ajuste->idAjuste
	
	var soma = cast(RelSomatorioAjuste ptr, relSomaAjustesDict->lookup(chave))
	if soma = null then
		soma = relSomaAjustesList->addOrdAsc(strptr(chave), @somaAjustesCmpCb)
		soma->chave = chave
		soma->idAjuste = ajuste->idAjuste
		soma->situacao = sit
		relSomaAjustesDict->add(soma->chave, soma)
	end if

	soma->valor += ajuste->icms
end sub

''''''''
sub EfdPdfExport.adicionarDocRelatorioItemAnal(sit as TipoSituacao, anal as TDocItemAnal ptr)
	
	if ISREGULAR(sit) then
		var row = gerarLinhaAnal()
		setChildText(row, "CST", format(anal->cst,"000"))
		setChildText(row, "CFOP", str(anal->cfop))
		setChildText(row, "ALIQ", DBL2MONEYBR(anal->aliq))
		setChildText(row, "BCICMS", DBL2MONEYBR(anal->bc))
		setChildText(row, "ICMS", DBL2MONEYBR(anal->ICMS))
		setChildText(row, "BCICMSST", DBL2MONEYBR(anal->bcST))
		setChildText(row, "ICMSST", DBL2MONEYBR(anal->ICMSST))
		setChildText(row, "IPI", DBL2MONEYBR(anal->IPI))
		setChildText(row, "VALOP", DBL2MONEYBR(anal->valorOp))
		if ultimoRelatorio = REL_LRE then
			setChildText(row, "REDBC", DBL2MONEYBR(anal->redBC))
		end if
	end if

end sub

''''''''
sub EfdPdfExport.adicionarDocRelatorioObs(sit as TipoSituacao, obs as TDocObs ptr, isFirst as boolean)
	
	if ISREGULAR(sit) then
		var lanc = cast( TObsLancamento ptr, obsLancamentoDict->lookup(obs->idLanc))
		var text = iif(lanc <> null, lanc->descricao, "")
		if len(obs->extra) > 0 then
			text += " " + obs->extra
		end if

		var textLen = ttfLen(text)
		var parts = cint(textLen / AJUSTE_MAX_DESC_LEN + 0.5)

		var row = gerarLinhaObs(isFirst, parts)
		
		var desc = row->getChild("DESC-OBS")
		if parts > 1 then
			desc->getParent()->setAttrib("h", LRS_OBS_HEIGHT + (8.0 * (parts-1)))
		end if
		
		var start = 0.0!
		for i as integer = 0 to parts-1
			var utf16le = latinToUtf16le(ttfSubstr(text, start, AJUSTE_MAX_DESC_LEN))
			desc->setAttrib("text", utf16le)
			deallocate utf16le
			if i < parts-1 then
				desc = desc->clone(desc->getParent(), relPage)
				desc->translateY(-8.0)
			end if
		next
	end if

end sub

''''''''
sub EfdPdfExport.adicionarDocRelatorioObsAjuste(sit as TipoSituacao, ajuste as TDocObsAjuste ptr, isFirst as boolean)
	
	if ISREGULAR(sit) then
		var row = gerarLinhaObsAjuste(isFirst)
		if ultimoRelatorio = REL_LRS then
			setChildText(row, "SIT-AJ", format(cdbl(sit),"00"))
		end if
		setChildText(row, "COD-AJ", ajuste->idAjuste)
		setChildText(row, "ITEM-AJ", ajuste->idItem)
		setChildText(row, "BC-AJ", DBL2MONEYBR(ajuste->bcIcms))
		setChildText(row, "ALIQ-AJ", DBL2MONEYBR(ajuste->aliqIcms))
		setChildText(row, "ICMS-AJ", DBL2MONEYBR(ajuste->icms))
		setChildText(row, "OUTROS-AJ", DBL2MONEYBR(ajuste->outros))
	end if

end sub

''''''''
static function EfdPdfExport.luacb_efd_rel_addItemAnalitico cdecl(L as lua_State ptr) as long
	var args = lua_gettop(L)
	
	lua_getglobal(L, "efd")
	var g_efd = cast(EfdExt ptr, lua_touserdata(L, -1))
	lua_pop(L, 1)
	
	if args = 2 then
		var sit = lua_tointeger(L, 1)
		
		dim as TDocItemAnal anal
		
		lua_pushnil(L)
		do while lua_next(L, -2) <> 0
			var value = lua_tonumber(L, -1)
			
			select case lcase(*lua_tostring(L, -2))
			case "cst"
				anal.cst = cint(value)
			case "cfop"
				anal.cfop = cint(value)
			case "aliq"
				anal.aliq = value
			case "valorop"
				anal.valorOp = value
			case "bc"
				anal.bc = value
			case "icms"
				anal.ICMS = value
			case "bcst"
				anal.bcST = value
			case "icmsst"
				anal.ICMSST = value
			case "redbc"
				anal.redBC = value
			case "ipi"
				anal.IPI = value
			end select
			
			lua_pop(L, 1)
		loop

		anal.next_ = null
		'adicionarDocRelatorioItemAnal(sit, @anal)
	end if
	
	function = 0
	
end function

''''''''
sub EfdPdfExport.adicionarDocRelatorioSaidas(doc as TDocDF ptr, part as TParticipante ptr, highlight as boolean, lg as boolean)
	var row = gerarLinhaDFe(lg, highlight)
	
	if len(doc->dataEmi) > 0 then
		setChildText(row, iif(lg, "DEMI-LG", "DEMI"), YyyyMmDd2DatetimeBR(doc->dataEmi))
	end if
	if len(doc->dataEntSaida) > 0 then
		setChildText(row, iif(lg, "DSAIDA-LG", "DSAIDA"), YyyyMmDd2DatetimeBR(doc->dataEntSaida))
	end if
	setChildText(row, iif(lg, "NRINI-LG", "NRINI"), str(doc->numero))
	setChildText(row, iif(lg, "MD-LG", "MD"), str(doc->modelo))
	setChildText(row, iif(lg, "SR-LG", "SR"), doc->serie)
	setChildText(row, iif(lg, "SUB-LG", "SUB"), doc->subserie)
	setChildText(row, iif(lg, "SIT-LG", "SIT"), format(cdbl(doc->situacao), "00"))
	
	if ISREGULAR(doc->situacao) then
		if part <> null then
			setChildText(row, iif(lg, "CNPJDEST-LG", "CNPJDEST"), iif(len(part->cpf) > 0, STR2CPF(part->cpf), STR2CNPJ(part->cnpj)))
			setChildText(row, iif(lg, "IEDEST-LG", "IEDEST"), part->ie)
			setChildText(row, iif(lg, "UFDEST-LG", "UFDEST"), MUNICIPIO2SIGLA(part->municip))
			setChildText(row, iif(lg, "MUNDEST-LG", "MUNDEST"), str(part->municip))
			var start = 0.0!
			setChildText(row, iif(lg, "RAZAODEST-LG", "RAZAODEST"), ttfSubstr(part->nome, start, LRS_MAX_NAME_LEN), true)
			if lg then
				setChildText(row, "RAZAODEST2-LG", ttfSubstr(part->nome, start, LRS_MAX_NAME_LEN), true)
			end if
		end if
	end if
end sub

''''''''
sub EfdPdfExport.adicionarDocRelatorioEntradas(doc as TDocDF ptr, part as TParticipante ptr, highlight as boolean, lg as boolean)
	var row = gerarLinhaDFe(lg, highlight)
	
	setChildText(row, iif(lg, "DEMI-LG", "DEMI"), YyyyMmDd2DatetimeBR(doc->dataEmi))
	setChildText(row, iif(lg, "DENT-LG", "DENT"), YyyyMmDd2DatetimeBR(doc->dataEntSaida))
	setChildText(row, iif(lg, "NRO-LG", "NRO"), str(doc->numero))
	setChildText(row, iif(lg, "MOD-LG", "MOD"), str(doc->modelo))
	setChildText(row, iif(lg, "SER-LG", "SER"), doc->serie)
	setChildText(row, iif(lg, "SUBSER-LG", "SUBSER"), doc->subserie)
	setChildText(row, iif(lg, "SIT-LG", "SIT"), format(cdbl(doc->situacao), "00"))
	if part <> null then
		setChildText(row, iif(lg, "CNPJEMI-LG", "CNPJEMI"), iif(len(part->cpf) > 0, STR2CPF(part->cpf), STR2CNPJ(part->cnpj)))
		setChildText(row, iif(lg, "IEEMI-LG", "IEEMI"), part->ie)
		setChildText(row, iif(lg, "UFEMI-LG", "UFEMI"), MUNICIPIO2SIGLA(part->municip))
		setChildText(row, iif(lg, "MUNEMI-LG", "MUNEMI"), codMunicipio2Nome(part->municip, municipDict, configDb))
		var start = 0.0!
		setChildText(row, iif(lg, "RAZAOEMI-LG", "RAZAOEMI"), ttfSubstr(part->nome, start, LRE_MAX_NAME_LEN), true)
		if lg then
			setChildText(row, "RAZAOEMI2-LG", ttfSubstr(part->nome, start, LRS_MAX_NAME_LEN), true)
		end if
	end if
end sub

''''''''
sub EfdPdfExport.adicionarDocRelatorioSaidas(doc as TECFReducaoZ ptr, highlight as boolean)
	var equip = doc->equipECF

	var row = gerarLinhaDFe(false, highlight)
	
	setChildText(row, "DEMI", YyyyMmDd2DatetimeBR(doc->dataMov))
	setChildText(row, "NRINI", str(doc->numIni))
	setChildText(row, "NRFIM", str(doc->numFim))
	setChildText(row, "NCAIXA", str(equip->numCaixa))
	setChildText(row, "ECF", equip->numSerie)
	setChildText(row, "MD", iif(equip->modelo = &h2D, "2D", str(equip->modelo)))
	setChildText(row, "SIT", "00")
end sub

''''''''
sub EfdPdfExport.adicionarDocRelatorioSaidas(doc as TDocSAT ptr, highlight as boolean)
	var row = gerarLinhaDFe(false, highlight)
	
	setChildText(row, "DEMI", YyyyMmDd2DatetimeBR(doc->dataEmi))
	setChildText(row, "NRINI", str(doc->numero))
	setChildText(row, "ECF", doc->serieEquip)
	setChildText(row, "MD", str(doc->modelo))
	setChildText(row, "SIT", format(cdbl(doc->situacao), "00"))
end sub

''''''''
sub EfdPdfExport.gerarResumoRelatorioHeader(emitir as boolean, isPre as boolean)
	relYPos += ROW_SPACE_BEFORE
	
	if not isPre then
		if emitir then
			var title = relPage->getNode("resumo-title")
			title->setAttrib("hidden", false)
			title->translateY(-relYPos)
		end if
	end if
	relYPos += iif(ultimoRelatorio = REL_LRS, LRS_RESUMO_TITLE_HEIGHT, LRE_RESUMO_TITLE_HEIGHT)

	if not isPre then
		if emitir then
			var header = relPage->getNode("resumo-header")
			header->setAttrib("hidden", false)
			header->translateY(-relYPos)
		end if
	end if
	relYPos += iif(ultimoRelatorio = REL_LRS, LRS_RESUMO_HEADER_HEIGHT, LRE_RESUMO_HEADER_HEIGHT)
end sub

''''''''
sub EfdPdfExport.gerarResumoAjustesRelatorioHeader(emitir as boolean, isPre as boolean)
	relYPos += ROW_SPACE_BEFORE
	
	if not isPre then
		if emitir then
			var title = relPage->getNode("resumo-ajustes-title")
			title->setAttrib("hidden", false)
			title->translateY(-relYPos)
		end if
	end if
	relYPos += iif(ultimoRelatorio = REL_LRS, LRS_RESUMO_TITLE_HEIGHT, LRE_RESUMO_TITLE_HEIGHT)

	if not isPre then
		if emitir then
			var header = relPage->getNode("resumo-ajustes-header")
			header->setAttrib("hidden", false)
			header->translateY(-relYPos)
		end if
	end if
	relYPos += iif(ultimoRelatorio = REL_LRS, LRS_RESUMO_HEADER_HEIGHT, LRE_RESUMO_HEADER_HEIGHT)
end sub

sub EfdPdfExport.gerarResumoRelatorio(emitir as boolean, isPre as boolean)
	var titleHeight = iif(ultimoRelatorio = REL_LRS, LRS_RESUMO_TITLE_HEIGHT, LRE_RESUMO_TITLE_HEIGHT)
	var headerHeight = iif(ultimoRelatorio = REL_LRS, LRS_RESUMO_HEADER_HEIGHT, LRE_RESUMO_HEADER_HEIGHT)
	var rowHeight = iif(ultimoRelatorio = REL_LRS, LRS_RESUMO_ROW_HEIGHT, LRE_RESUMO_ROW_HEIGHT)
	
	'' header
	if (relPage = null andalso not isPre) orElse relYPos + ROW_SPACE_BEFORE + titleHeight + headerHeight + rowHeight > PAGE_BOTTOM then
		criarPaginaRelatorio(emitir, isPre)
	end if
	
	gerarResumoRelatorioHeader(emitir, isPre)

	'' tabela de totais
	dim as RelSomatorioAnal totSoma
	
	scope
		var soma = cast(RelSomatorioAnal ptr, relSomaAnalList->head)
		do while soma <> null
			if relYPos + rowHeight > PAGE_BOTTOM then
				criarPaginaRelatorio(emitir, isPre)
				gerarResumoRelatorioHeader(emitir, isPre)
			end if
		
			if not isPre then
				if emitir then
					var org = relPage->getNode("resumo-row")
					var row = org->clone(relPage, relPage)
				
					row->setAttrib("hidden", false)
					row->translateY(-relYPos)
					
					if ultimoRelatorio = REL_LRS then
						setChildText(row, "SIT", format(cdbl(soma->situacao), "00"))
					end if	
				
					setChildText(row, "CST", format(soma->cst,"000"))
					setChildText(row, "CFOP", str(soma->cfop))
					setChildText(row, "ALIQ", DBL2MONEYBR(soma->aliq))
					setChildText(row, "OPER", DBL2MONEYBR(soma->valorOp))
					setChildText(row, "BCICMS", DBL2MONEYBR(soma->bc))
					setChildText(row, "ICMS", DBL2MONEYBR(soma->icms))
					setChildText(row, "BCICMSST", DBL2MONEYBR(soma->bcST))
					setChildText(row, "ICMSST", DBL2MONEYBR(soma->ICMSST))
					setChildText(row, "IPI", DBL2MONEYBR(soma->ipi))
				end if
			end if
			relYPos += rowHeight
			
			if not isPre then
				totSoma.valorOp += soma->valorOp
				totSoma.bc += soma->bc
				totSoma.icms += soma->icms
				totSoma.bcST += soma->bcST
				totSoma.ICMSST += soma->ICMSST
				totSoma.ipi += soma->ipi
			end if
			
			soma = relSomaAnalList->next_(soma)
		loop
	end scope
	
	'' totais
	if relYPos + ROW_SPACE_BEFORE + headerHeight > PAGE_BOTTOM then
		criarPaginaRelatorio(emitir, isPre)
		gerarResumoRelatorioHeader(emitir, isPre)
	end if
	
	relYPos += ROW_SPACE_BEFORE

	if not isPre then
		if emitir then
			var total = relPage->getNode("resumo-total")
			total->setAttrib("hidden", false)
			total->translateY(-relYPos)

			setChildText(total, "OPERTOT", DBL2MONEYBR(totSoma.valorOp))
			setChildText(total, "BCICMSTOT", DBL2MONEYBR(totSoma.bc))
			setChildText(total, "ICMSTOT", DBL2MONEYBR(totSoma.icms))
			setChildText(total, "BCICMSSTTOT", DBL2MONEYBR(totSoma.bcST))
			setChildText(total, "ICMSSTTOT", DBL2MONEYBR(totSoma.ICMSST))
			setChildText(total, "IPITOT", DBL2MONEYBR(totSoma.ipi))
		end if
	end if
	relYPos += headerHeight

	'' tabela de ajustes
	scope
		rowHeight += iif(ultimoRelatorio = REL_LRS, 3.5, 6.0)
		var soma = cast(RelSomatorioAjuste ptr, relSomaAjustesList->head)
		if soma <> null then
			if relYPos + ROW_SPACE_BEFORE + titleHeight + headerHeight + rowHeight > PAGE_BOTTOM then
				criarPaginaRelatorio(emitir, isPre)
			end if
			
			gerarResumoAjustesRelatorioHeader(emitir, isPre)
		
			do while soma <> null
				if relYPos + rowHeight > PAGE_BOTTOM then
					criarPaginaRelatorio(emitir, isPre)
					gerarResumoAjustesRelatorioHeader(emitir, isPre)
				end if
			
				if not isPre then
					if emitir then
						var org = relPage->getNode("resumo-ajustes-row")
						var row = org->clone(relPage, relPage)
					
						row->setAttrib("hidden", false)
						row->translateY(-relYPos)
						
						if ultimoRelatorio = REL_LRS then
							setChildText(row, "RES-SIT-AJ", format(cdbl(soma->situacao), "00"))
						end if	
					
						setChildText(row, "RES-COD-AJ", soma->idAjuste)
						var desc = configDb->execScalar("select descricao from CodAjusteDoc where codigo = '" & soma->idAjuste & "'")
						if desc <> null then
							var len_ = ttfLen(desc)
							var start = 0.0!
							setChildText(row, "RES-DESC-AJ", ttfSubstr(desc, start, RESUMO_AJUSTE_MAX_DESC_LEN))
							if len_ > cint(RESUMO_AJUSTE_MAX_DESC_LEN + 0.5) then
								setChildText(row, "RES-DESC2-AJ", ttfSubstr(desc, start, RESUMO_AJUSTE_MAX_DESC_LEN))
							end if
						end if
						setChildText(row, "RES-VALOR-AJ", DBL2MONEYBR(soma->valor))
					end if
				end if
				relYPos += rowHeight
				
				soma = relSomaAnalList->next_(soma)
			loop
		end if
	end scope
	
end sub

''''''''
sub EfdPdfExport.finalizarRelatorio(isPre as boolean)

	if ultimoRelatorio = -1 then
		return
	end if
	
	select case ultimoRelatorio
	case REL_LRE, REL_LRS
		if nroRegistrosRel = 0 then
			criarPaginaRelatorio(true, isPre)
			if not isPre then
				var empty = relPage->getNode("empty")
				empty->setAttrib("hidden", false)
			end if
			emitirPaginaRelatorio(true, isPre)
		
		else
			var resumir_ = true
			if relNroLinhas > 0 then
				var paginaGerada = gerarPaginaRelatorio(true, isPre)
				if not paginaGerada then
					resumir_ = false
				end if
			else
				if opcoes->filtrarCnpj orelse opcoes->filtrarChaves then
					resumir_ = false
				end if
				criarPaginaRelatorio(resumir_, isPre)
			end if
			gerarResumoRelatorio(resumir_, isPre)
		end if

		delete relSomaAnalDict
		delete relSomaAnalList
		delete relSomaAjustesDict
		delete relSomaAjustesList
	end select
	
	if relPage <> null then
		emitirPaginaRelatorio(true, isPre)
	end if
	
	'' salvar PDF
	if not isPre then
		relOutFile->saveTo(DdMmYyyy2Yyyy_Mm(regMestre->dataIni) + "_" + ultimoRelatorioSufixo + ".pdf")
		delete relOutFile
	end if
	
	if not isPre then
		delete relTemplate
	end if

	ultimoRelatorio = -1

end sub