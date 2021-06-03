const FormData = require('form-data');
const nodeFetch = require('node-fetch');
const fetch = require('fetch-cookie/node-fetch')(nodeFetch);
const iconv = require('iconv-lite');
const {memoize} = require('./Util');

const ROOT_PATH = 'https://www.documentos.spsempapel.sp.gov.br';
const BASE_PATH = ROOT_PATH + '/sigaex/app/';
const LOGIN_URL = ROOT_PATH + '/siga/public/app/login';
const USER_URL  = ROOT_PATH + '/siga/api/v1/pessoas';

const CONTENT_TYPE_TEXT = 0
const CONTENT_TYPE_JSON = 1;
const CONTENT_TYPE_RAW = 2;

const iconToIcon = {
	'fas fa-hourglass-end': 'alert',
	'fas fa-inbox': 'inbox',
	'fas fa-lightbulb': 'lightbulb',
	'fas fa-clock': 'alarm',
	'fas fa-tags': 'tag'
};

const findAllDocsTemplate = {
	"popup":"",
	"propriedade":"",
	"postback":"1",
	"apenasRefresh":"0",
	"paramoffset":"0",
	"p.offset":"0",
	"descrDocumento":"",
	"ultMovIdEstadoDoc":"9", //Juntada
	"ultMovTipoResp":"2",
	"requltMovRespSel":"",
	"alterouSel":"",
	"ultMovRespSel.id":"",
	"ultMovRespSel.descricao":"",
	"ultMovRespSel.buscar":"",
	"ultMovRespSel.sigla":"",
	"requltMovLotaRespSel":"",
	"ultMovLotaRespSel.id":"",
	"ultMovLotaRespSel.descricao":"",
	"ultMovLotaRespSel.buscar":"",
	"ultMovLotaRespSel.sigla":"",
	"orgaoUsu":"118", // SEFAZ-SP
	"dtDocString": "",
	"dtDocFinalString": "",
	"idTipoFormaDoc":"0",
	"idFormaDoc":"8", // DES -- Despacho
	"idMod":"0",
	"anoEmissaoString":"0",
	"numExpediente":"",
	"numExtDoc":"",
	"reqcpOrgaoSel":"",
	"cpOrgaoSel.id":"",
	"cpOrgaoSel.descricao":"",
	"cpOrgaoSel.buscar":"",
	"cpOrgaoSel.sigla":"",
	"numAntigoDoc":"",
	"nmSubscritorExt":"",
	"reqsubscritorSel":"",
	"subscritorSel.id":"",
	"subscritorSel.descricao":"",
	"subscritorSel.buscar":"",
	"subscritorSel.sigla":"",
	"tipoCadastrante":"2",
	"reqcadastranteSel":"",
	"cadastranteSel.id":"",
	"cadastranteSel.descricao":"",
	"cadastranteSel.buscar":"",
	"cadastranteSel.sigla":"",
	"reqlotaCadastranteSel":"",
	"lotaCadastranteSel.id":"",
	"lotaCadastranteSel.descricao":"",
	"lotaCadastranteSel.buscar":"",
	"lotaCadastranteSel.sigla":"",
	"tipoDestinatario":"2",
	"reqdestinatarioSel":"",
	"destinatarioSel.id":"",
	"destinatarioSel.descricao":"",
	"destinatarioSel.buscar":"",
	"destinatarioSel.sigla":"",
	"reqlotacaoDestinatarioSel":"",
	"lotacaoDestinatarioSel.id":"",
	"lotacaoDestinatarioSel.descricao":"",
	"lotacaoDestinatarioSel.buscar":"",
	"lotacaoDestinatarioSel.sigla":"",
	"reqorgaoExternoDestinatarioSel":"",
	"orgaoExternoDestinatarioSel.id":"",
	"orgaoExternoDestinatarioSel.descricao":"",
	"orgaoExternoDestinatarioSel.buscar":"",
	"orgaoExternoDestinatarioSel.sigla":"",
	"nmDestinatario":"",
	"reqclassificacaoSel":"",
	"classificacaoSel.id":"",
	"classificacaoSel.descricao":"",
	"classificacaoSel.buscar":"",
	"classificacaoSel.sigla":"",
	"ordem":"0",
	"visualizacao":"0"
  };

class SigaApi 
{
	async logon(username, password)
	{
		const data = new FormData();
		data.append('username', username);
		data.append('password', password);
		
		const res = await this.requestURL('POST', LOGIN_URL, data, {responseType: CONTENT_TYPE_TEXT});
		if(res.errors !== null)
		{
			return res;
		}
		else if(res.status === 200)
		{
			if(res.data !== null && res.data.indexOf('"app/principal"') === -1)
			{
				return {errors: ['Usuário e/ou senha inválidos'], data: null};
			}
		}
		else if(res.status !== 302)
		{
			return {errors: ['Usuário e/ou senha inválidos'], data: null};
		}

		const user = await this.findUser(username);
		return {errors: null, data: user || {}};
	}

	findUser = memoize(async (cpfOrId) =>
	{
		const res = await this.requestURL('GET', `${USER_URL}?${cpfOrId.length === 11? 'cpf': 'idPessoaIni'}=${cpfOrId}`, null, {responseType: CONTENT_TYPE_JSON});
		if(res.errors !== null)
		{
			return null;
		}

		const data = res.data;
		return data.list && data.list.length > 0?
			data.list[0]:
			{};
	});

	static remapIcon(icon)
	{
		return iconToIcon[icon] || 'folder';
	}

	findGroups = memoize(async (daLotacao = false, idVisualizacao = 0) =>
	{
		const buildFormData = (params) =>
		{
			const data = new FormData();
			data.append('exibeLotacao', daLotacao.toString());
			data.append('trazerAnotacoes', true.toString());
			data.append('trazerComposto', false.toString());
			data.append('trazerArquivados', false.toString());
			data.append('trazerCancelados', false.toString());
			data.append('ordemCrescenteData', true.toString());
			data.append('idVisualizacao', idVisualizacao);
			data.append('parms', JSON.stringify(params));
			return data;
		};

		// primeiro carregar os grupos da raiz
		let res = await this.post('mesa2.json', buildFormData({}), {responseType: CONTENT_TYPE_JSON});
		if(res.errors !== null)
		{
			return res;
		}

		// após, recarregar grupos não vazios com seus documentos
		const params = {};
		res.data.forEach(group =>
		{
			if(group.grupoCounterAtivo > 0)
			{
				params[group.grupoNome] = {
					grupoOrdem: group.grupoOrdem,
					grupoQtd: 1000,
					grupoQtdPag: 1000,
					grupoCollapsed: false
				};
			}
		});

		res = await this.post('mesa2.json', buildFormData(params), {responseType: CONTENT_TYPE_JSON});
		if(res.errors !== null)
		{
			return res;
		}
		
		return {
			errors: null,
			data: res.data.map(group => ({
				...group,
				grupoDocs: group.grupoDocs?
					group.grupoDocs.map(doc => ({
						...doc,
						descr: doc.descr? 
							doc.descr.replace('Complemento do Assunto: ', ''):
							''
					})):
					null,
				grupoIcone: SigaApi.remapIcon(group.grupoIcone)
			}))
		};
	}, {ttl: 30*1000});

	compareGroups(v1, v2)
	{
		if(!v1)
		{
			return !v2;
		}
		else if(!v2)
		{
			return false;
		}

		if(v1.constructor !== Array || v2.constructor !== Array)
		{
			throw new Error('v1 and v2 should be Arrays');
		}

		if(v1.length !== v2.length)
		{
			return false;
		}

		for(let i = 0; i < v1.length; i++)
		{
			const g1 = v1[i];
			const g2 = v2.find(g => g.grupo === g1.grupo);
			if(!g2)
			{
				return false;
			}

			if(g1.grupoCounterAtivo !== g2.grupoCounterAtivo)
			{
				return false;
			}

			if(!g1.grupoDocs)
			{
				if(g2.grupoDocs)
				{
					return false;
				}
			}
			else if(!g2.grupoDocs)
			{
				return false;
			}

			if(g1.grupoDocs)
			{
				if(g1.grupoDocs.length !== g2.grupoDocs.length)
				{
					return false;
				}

				for(let j = 0; j < g1.grupoDocs.length; j++)
				{
					const d1 = g1.grupoDocs[j];
					const d2 = g2.grupoDocs.find(d => d.codigo === d1.codigo);
					if(!d2)
					{
						return false;
					}

					const mov1 = d1.list;
					const mov2 = d2.list;
					if(!mov1)
					{
						if(mov2)
						{
							return false;
						}
					}
					else if(!mov2)
					{
						return false;
					}

					if(mov1.length !== mov2.length)
					{
						return false;
					}

					for(let k = 0; k < mov1.length; k++)
					{
						const m1 = mov1[k];
						const m2 = mov2.find(m => m.nome === m1.nome);
						if(!m2)
						{
							return false;
						}
					}
				}
			}
		}

		for(let i = 0; i < v2.length; i++)
		{
			const g2 = v2[i];
			const g1 = v1.find(g => g.grupo === g2.grupo);
			if(!g1)
			{
				return false;
			}
		}

		return true;
	}

	findPdf = memoize(async (nome, semMarcas, onProgress) =>
	{
		const extractText = (from, pattern) =>
		{
			const matches = from.match(pattern);
			return matches? 
				matches[1]: 
				'';
		};
		
		// dar início a geração do PDF
		const res = await this.get(
			`arquivo/exibir?idVisualizacao=0&arquivo=${nome}.pdf&completo=1&semmarcas=${semMarcas? 1: 0}`, 
			{responseType: CONTENT_TYPE_TEXT});
		if(res.errors !== null)
		{
			return null;
		}

		// encontrar URL e id do PDF
		const url = extractText(res.data, /window\.location = "(.*?)"/);

		const id = extractText(res.data, /this\.start\('[a-zA-Z0-9\-_.]+', '(.*?)'/);

		// aguardar geração do PDF terminar
		// eslint-disable-next-line no-constant-condition
		while(true)
		{
			const res = await this.requestURL(
				'GET', 
				ROOT_PATH + `/sigaex/api/v1/status/${id}`,
				null,
				{responseType: CONTENT_TYPE_JSON});

			if(res.errors !== null)
			{
				return null;
			}
			
			if(res.data.indice === res.data.contador)
			{
				break;
			}

			onProgress && onProgress(res.data.indice / res.data.contador);
		}

		return ROOT_PATH + url;
	}, {ttl: 5*60*1000});

	findDocParts = memoize(async (sigla) =>
	{
		const extrairPartes = (text) =>
		{
			const res = [];
			while(text.length > 0)
			{
				const match = /javascript:exibir\('(.*?)','(.*?)',''\)">(.*?)<\/a>/.exec(text);
				if(!match)
				{
					break;
				}

				if(match[2].indexOf('&completo=1') === -1)
				{
					const title = match[3].trim();
					res.push({
						sigla: match[2].replace('.pdf', ''),
						title: title !== sigla? 
							title:
							'COMPLETO',
						isFullDoc: title === sigla,
						url: null
					});
				}

				text = text.substr(match.index + match[0].length);
			}

			return res;
		};

		// não existe API para listar as partes de um documento, então temos que extrair dados da página HTML mesmo....
		const res = await this.get(
			`expediente/doc/exibirProcesso?sigla=${sigla}&`, 
			{responseType: CONTENT_TYPE_TEXT});
		if(res.errors !== null)
		{
			return null;
		}

		const text = res.data.replace(/[\r\n]/g, '');
		const partes = extrairPartes(text);

		return partes;
	}, {ttl: 5*60*1000});

	async findAllDocs(q)
	{
		const data = new FormData();
		const query = Object.assign({}, findAllDocsTemplate, q);
		Object.entries(query).forEach(([key, value]) => data.append(key, value));
		const res = await this.post('expediente/doc/exportarCsv', data, {responseType: CONTENT_TYPE_RAW})
		if(res.errors)
		{
			return res;
		}

		return {
			errors: null,
			data: iconv.decode(res.data, 'ISO-8859-1')
		};
	}

	findMainDoc = memoize(async (subDoc) =>
	{
		const res = await this.get(`expediente/doc/exibirHistorico?sigla=${subDoc}`, {responseType: CONTENT_TYPE_TEXT})
		if(res.errors)
		{
			return res;
		}

		const body = res.data.replace(/[\r\n\t]/g, '');

		const q = 'Documento Pai:</b><a href="/sigaex/app/expediente/doc/exibir?sigla=';
		const s = body.indexOf(q);
		if(s < 0)
		{
			return {
				errors: ['Documento pai não encontrado']
			};
		}

		const e = body.substring(s + q.length).indexOf('"');

		return {
			errors: null,
			data: body.substring(s + q.length, s + q.length + e)
		};
	});

	findDocDetails = memoize(async (num) =>
	{
		const res = await this.get(`expediente/doc/exibir?sigla=${num}`, {responseType: CONTENT_TYPE_TEXT})
		if(res.errors)
		{
			return res;
		}

		const body = res.data.replace(/[\r\n\t]/g, '');

		// encontrar descrição
		const q = '<p id="descricao"><b>Descrição:</b>';
		const s = body.indexOf(q);
		if(s < 0)
		{
			return {
				errors: ['Descrição não encontrada']
			};
		}

		const e = body.substring(s + q.length).indexOf('</p>');
		const desc = body.substring(s + q.length, s + q.length + e);

		return {
			errors: null,
			data: {
				'Número': num,
				'Descrição': desc.replace('Complemento do Assunto: ', '')
			}
		};

	});

	async requestURL(
		method, 
		url, 
		data = null, 
		{
			requestType = CONTENT_TYPE_RAW, 
			responseType = CONTENT_TYPE_JSON, 
		})
	{
		try
		{
			const options = {
				method: method,
				headers: {
					'Accept-Encoding': 'gzip,deflate',
				}
			};

			if(data !== null)
			{
				options.body = requestType !== CONTENT_TYPE_JSON? 
					data: 
					JSON.stringify(data);
			}

			let errors = null;
			
			const res = await fetch(url, options)
				.catch((e) => {if(!errors) errors = e.message;});

			if(errors === null && res && res.ok)
			{
				try
				{
					const body = responseType === CONTENT_TYPE_JSON && res.json && res.json.constructor === Function? 
						await res.json(): 
						responseType === CONTENT_TYPE_TEXT?
						 	await res.text():
							await res.buffer();

					return {
						errors: null, 
						data: body, 
						status: res.status, 
						headers: res.headers
					};
				}
				catch(e)
				{
					return {
						errors: [e.message], 
						data: null
					};
				}
			}
			else
			{
				const body = res? 
					responseType === CONTENT_TYPE_JSON && res.json && res.json.constructor === Function? 
						await res.json(): 
						res.text && res.text.constructor === Function? 
							await res.text():
							null:
					null;
				
				return {
					errors: errors || [], 
					data: body, 
					status: res && res.status
				};
			}
		}
		catch (e)
		{
			return {
				errors: [e.message], 
				data: null
			};
		}

	}

	get(path, options = {})
	{
		return this.requestURL('GET', BASE_PATH + path, null, options);
	}

	post(path, data, options = {})
	{
		return this.requestURL('POST', BASE_PATH + path, data, options);
	}

	put(path, data, options = {})
	{
		return this.requestURL('PUT', BASE_PATH + path, data, options);
	}

	patch(path, data, options = {})
	{
		return this.requestURL('PATCH', BASE_PATH + path, data, options);
	}

	del(path, options = {})
	{
		return this.requestURL('DELETE', BASE_PATH + path, null, options);
	}
}

module.exports = SigaApi;