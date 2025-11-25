'' Impressora de EFD
'' Copyright 2022-2025 André Vicentini (avtvicentini)
'' Licenciado sob GNU GPL-2.0-ou-posterior

#include once "EfdExt.bi"
#include once "EfdGUI.bi"
#include once "winmin.bi"

declare sub main()

on error goto exceptionReport

'''''''''''   
sub mostrarCopyright()
	print wstr("Impressoar de EFD, versão 1.0.1 beta")
	print wstr("Copyright 2022-2025 by André Vicentini (avtvicentini)")
	print
end sub

'''''''''''
sub mostrarUso()
	print wstr("Modo de usar:")
	print wstr("EfdPrinter.exe Opções efd.txt")
	print wstr("Notas:")
	print wstr(!" 1. No lugar do nome dos arquivos, podem ser usadas máscaras,")
	print wstr(!"    como por exemplo: *.txt")
	print wstr("Opções:")
	print wstr(!" -filtrarCnpjs cnpj1,cnpj2,...:")
	print wstr(!"  Extrai somente os registros com os mesmos CNPJs (de emitentes ou")
	print wstr(!"  destinatários) dos contidos na lista de CNPJs informada (separada por")
	print wstr(!"  vírgula; zeros à esq).")
	print wstr(!" -filtrarChaves chave1,chave2,... ou @arquivo:")
	print wstr(!"  Extrai somente os registros com as mesmas chaves das contidas na lista")
	print wstr(!"  (utilizar @arquivo.txt para carregar as chaves de um arquivo, com uma")
	print wstr(!"  chave por linha, sem linhas vazias ou espaços entre as chaves).")
	print wstr(!" -realcar:")
	print wstr(!"  Cria um realce, nos relatórios em PDF, nos registros que corresponderem")
	print wstr(!"  à -filtrarCnpjs ou -filtrarChaves.")
	print wstr(!" -naoGerarLre, -naoGerarLrs e -naoGerarLraicms:")
	print wstr(!"  Deixam de gerar os respectivos livros quando -gerarRelatorios é utilizada.")
	
	print 
end sub

'''''''''''
function onProgress(estagio as const zstring ptr, percent as double) as boolean
	static ultpercent as double = 0
	
	if estagio <> null then
		var s = latinToUtf16le(estagio)
		print *s;
		deallocate s
	end if
	
	if percent = 0 then
		ultpercent = 0
		return true
	end if
	
	var jaCompletado = ultpercent >= 1.0
	
	if not jaCompletado then
		do while percent >= ultpercent + 0.05
			print ".";
			ultpercent += 0.05
		loop
		
		if percent = 1.0 then
			ultpercent = 1.0
			print "OK!"
		end if
	end if

	return true
end function

sub onError(msg as const zstring ptr)
	var s = latinToUtf16le(msg)
	print "Erro: "; *s
	deallocate s
end sub

'''''''''''
sub main()
	dim opcoes as OpcoesExtracao
	
	randomize , 1
	
	if len(command(1)) = 0 then
		FreeConsole()
		var gui = new EfdGUI()
		gui->build()
		gui->run()
		delete gui
		exit sub
	end if
   
	mostrarCopyright()
   
	'' verificar opções
	var nroOpcoes = 0
	var i = 1
	do 
		var arg = command(i)
		if len(arg) = 0 then
			exit do
		end if
		
		if arg[0] = asc("-") then
			select case lcase(arg)
			case "-ajuda"
				mostrarUso()
				exit sub
			case "-naogerarlre"
				opcoes.pularLre = true
				nroOpcoes += 1
			case "-naogerarlrs"
				opcoes.pularLrs = true
				nroOpcoes += 1
			case "-naogerarlrelrs"
				opcoes.pularLre = true
				opcoes.pularLrs = true
				nroOpcoes += 1
			case "-naogerarlraicms"
				opcoes.pularLraicms = true
				nroOpcoes += 1
			case "-naogerarciap"
				opcoes.pularCiap = true
				nroOpcoes += 1
			case "-realcar"
				opcoes.highlight = true
			case "-filtrarcnpjs"
				i += 1
				var listaCnpj = command(i)
				if( len(listaCnpj) > 0 ) then
					splitstr(listaCnpj, ",", opcoes.listaCnpj())
					opcoes.filtrarCnpj = true
				else
					opcoes.filtrarCnpj = false
				end if
				nroOpcoes += 2
			case "-filtrarchaves"
				i += 1
				var listaChaves = command(i)
				if( len(listaChaves) > 0 ) then
					if left(listaChaves, 1) = "@" then
						var lista = mid(listaChaves, 2)
						if loadstrings(lista, opcoes.listaChaves()) = 0 then
							onError(wstr("ao carregar arquivo: " + lista))
							exit sub
						end if
					else
						splitstr(listaChaves, ",", opcoes.listaChaves())
					end if
					opcoes.filtrarChaves = true
				else
					opcoes.filtrarChaves = false
				end if
				nroOpcoes += 2
			case else
				onError(wstr("opção inválida: " + arg))
				exit sub
			end select
		end if
		
		i += 1
	loop
	
	if len(command(nroOpcoes+1)) = 0 then
		mostrarUso()
		return
	end if
	
	var ext = new EfdExt(@onProgress, @onError)
	
	'' 
	if ext->iniciar(opcoes) then
		'' mais de um arquivo informado?
		if len(command(nroOpcoes+2)) > 0 then
			'' carregar arquivos .txt com EFD
			var i = nroOpcoes+1
			var arquivoEntrada = command(i)
			do while len(arquivoEntrada) > 0
				if lcase(right(arquivoEntrada,3)) = "txt" then
					onProgress("Carregando arquivo: " + arquivoEntrada, 0)
					var txt = ext->carregarTxt( arquivoEntrada )
					if txt = null  then
						onError(!"\r\nErro ao carregar arquivo: " & arquivoEntrada)
						end -1
					end if
					
					print "Processando:"
					if not ext->processar( txt, arquivoEntrada ) then
						onError(!"\r\nErro ao extrair arquivo: " & arquivoEntrada)
						end -1
					end if
					
					if txt <> null then
						delete txt
					end if
				end if 
				
				i += 1
				arquivoEntrada = command(i)
			loop
		   
		'' só um arquivo .txt informado..
		else
			var arquivoEntrada = command(nroOpcoes+1)
			onProgress("Carregando arquivo: " + arquivoEntrada, 0)
			var txt = ext->carregarTxt( arquivoEntrada )
			if txt = null  then
				onError(!"\r\nErro ao carregar arquivo: " & arquivoEntrada)
				end -1
			end if
		
			print "Processando:"
			if not ext->processar( txt, arquivoEntrada ) then
				onError(!"\r\nErro ao extrair arquivo: " & arquivoEntrada)
				end -1
			end if
			
			delete txt
		end if
	end if
   
	''
	ext->finalizar()
	delete ext
	
end sub

main()
end 0

exceptionReport:
	onError(wstr(!"\r\nErro não tratado (" & Err & ") no módulo(" & *Ermn & ") na função(" & *Erfn & ") na linha (" & erl & !")\r\n"))
	end 1