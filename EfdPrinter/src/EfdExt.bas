
#include once "EfdExt.bi"
#include once "EfdSpedImport.bi"
#include once "EfdPdfExport.bi"
#include once "libs/BFile.bi"
#include once "libs/Dict.bi"
#include once "libs/SQLite.bi"
#include once "libs/trycatch.bi"
#undef imp

''''''''
constructor EfdExt(onProgress as OnProgressCB, onError as OnErrorCB)
	
	'' eventos
	this.onProgress = onProgress
	this.onError = onError
	
	''
	baseTemplatesDir = ExePath() + "\templates\"
	
	municipDict = new TDict(2^10, true, true, true)
	
	''
	configDb = new SQLite
	configDb->open(ExePath + "\db\config.db")
	
end constructor

destructor EfdExt()

	''
	configDb->close()
	delete configDb
	
	''
	delete municipDict
	
end destructor

''''''''
function EfdExt.iniciar(opcoes as OpcoesExtracao) as boolean
	
	''
	this.opcoes = opcoes
	
	return true
	
end function

''''''''
sub EfdExt.finalizar()

end sub

function EfdExt.carregarTxt(nomeArquivo as string) as EfdBaseImport_ ptr
	
	var imp = cast(EfdBaseImport_ ptr, null)
	
	if instr(nomeArquivo, "SpedEFD") >= 0 then
		imp = (new EfdSpedImport(@opcoes)) _
			->withCallbacks(onProgress, onError)
	else
		return null
	end if
	
	if imp->carregar(nomeArquivo) then
		return imp
	else
		delete imp
		return null
	end if
	
end function

''''''''
function EfdExt.processar(imp as EfdBaseImport_ ptr, nomeArquivo as string) as Boolean
   
	onProgress(null, 1)
	
	if imp->getTipoArquivo() = TIPO_ARQUIVO_EFD then
		var infAssinatura = cast(EfdSpedImport ptr, imp)->lerInfoAssinatura(nomeArquivo)
	
		var rel = (new EfdPdfExport(baseTemplatesDir, infAssinatura, @opcoes)) _
			->withDBs(configDb) _
			->withCallbacks(onProgress, onError) _
			->withFiltros(@filtrarPorCnpj, @filtrarPorChave) _
			->withDicionarios(imp->getParticipanteDict(), imp->getItemIdDict(), imp->getInfoComplDict(), _
				imp->getObsLancamentoDict(), imp->getBemCiapDict(), imp->getContaContabDict(), imp->getCentroCustoDict(), _
				municipDict)
			
		rel->gerar(imp->getFirstReg(), imp->getMestreReg(), imp->getNroRegs())
		
		delete rel
		
		if infAssinatura <> NULL then
			delete infAssinatura
		end if
	end if
	
	function = true
end function
