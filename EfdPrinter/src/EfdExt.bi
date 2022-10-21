
#include once "libs/Dict.bi"
#include once "libs/BFile.bi"
#include once "libs/SQLite.bi"
#include once "libs/PDFer.bi"

type OnProgressCB as function(estagio as const zstring ptr, porCompleto as double) as boolean
type OnErrorCB as sub(msg as const zstring ptr)
type OnFilterByStrCB as function(key as const zstring ptr, arr() as string) as boolean

type OpcoesExtracao
	pularLre 						as boolean = false
	pularLrs 						as boolean = false
	pularLraicms					as boolean = false
	pularCiap						as boolean = false
	filtrarCnpj						as boolean = false
	filtrarChaves					as boolean = false
	listaCnpj(any)					as string
	listaChaves(any)				as string
	highlight						as boolean
end type

#include once "EfdBaseImport.bi"
type EfdBaseImport_ as EfdBaseImport

enum TipoLivro
	TL_ENTRADAS
	TL_SAIDAS
end enum

enum TipoRegime
	TR_RPA				= 2
	TR_ESTIMATIVA		= 3
	TR_SIMPLIFICADO		= 4
	TR_MICROEMPRESA		= 5
	TR_RPA_DECENDIAL	= asc("A")
	TR_SN				= asc("N")
	TR_SN_MEI			= asc("O") 
	TR_EPP				= asc("M")
	TR_EPP_A			= asc("G")
	TR_EPP_B			= asc("H")
	TR_RURAL_PF			= asc("P")
end enum

type EfdExt
public:
	declare constructor (onProgress as OnProgressCB, onError as OnErrorCB)
	declare destructor ()
	declare function iniciar(opcoes as OpcoesExtracao) as boolean
	declare sub finalizar()
	declare function carregarTxt(nomeArquivo as String) as EfdBaseImport_ ptr
	declare function processar(imp_ as EfdBaseImport_ ptr, nomeArquivo as string) as Boolean
	onProgress 				as OnProgressCB
	onError 				as OnErrorCB
   
private:
	'' dicionários
	municipDict				as TDict ptr
	
	''
	opcoes					as OpcoesExtracao
	baseTemplatesDir		as string

	'' base de dados de configuração
	configDb				as SQLite ptr
end type

#include once "misc.bi"
#include once "strings.bi"

