
const ROOT_PATH = 'https://www.documentos.spsempapel.sp.gov.br';
const BASE_PATH = ROOT_PATH + '/sigaex/app/';
const LOGIN_URL = ROOT_PATH + '/siga/public/app/login';
const USER_URL  = ROOT_PATH + '/siga/api/v1/pessoas';

export default class SigaApi 
{
	async logon(username, password)
	{
		const data = new FormData();
		data.append('username', username);
		data.append('password', password);
		
		const res = await this.requestURL('POST', LOGIN_URL, data, {isJsonResponse: false});
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

		const user = await this.loadUser(username);
		return {errors: null, data: user || {}};
	}

	async loadUser(cpf)
	{
		const res = await this.requestURL('GET', `${USER_URL}?cpf=${cpf}`, null, {isJsonResponse: true});
		if(res.errors !== null)
		{
			return null;
		}

		const data = res.data;
		return data.list && data.list.length > 0?
			data.list[0]:
			{};
	}

	async loadGroups(daLotacao = false, idVisualizacao = 0)
	{
		const buildFormData = (params) =>
		{
			const data = new FormData();
			data.append('exibeLotacao', daLotacao);
			data.append('trazerAnotacoes', true);
			data.append('trazerComposto', false);
			data.append('trazerArquivados', false);
			data.append('trazerCancelados', false);
			data.append('ordemCrescenteData', true);
			data.append('idVisualizacao', idVisualizacao);
			data.append('parms', JSON.stringify(params));
			return data;
		};

		// primeiro carregar os grupos da raiz
		let res = await this.post('mesa2.json', buildFormData({}));
		if(res.errors !== null)
		{
			return null;
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

		res = await this.post('mesa2.json', buildFormData(params));
		if(res.errors !== null)
		{
			return null;
		}
		
		return res.data;
	}

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

	async loadPdf(nome, semMarcas, onProgress)
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
			{isJsonResponse: false});
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
				{isJsonResponse: true});

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
	}

	async requestURL(
		method, 
		url, 
		data = null, 
		{
			isJsonRequest = false, 
			isJsonResponse = true, 
			abortController = null
		})
	{
		try
		{
			const options = {
				credentials: 'include',
				method: method,
				signal: abortController && abortController.signal
			};

			if(data !== null)
			{
				options.body = !isJsonRequest? 
					data: 
					JSON.stringify(data);
			}

			let errors = null;
			const res = await fetch(url, options)
				.catch((e) => errors = e);

			if(errors === null && res && res.ok)
			{
				try
				{
					const body = isJsonResponse && res.json && res.json.constructor === Function? 
						await res.json(): 
						await res.text();

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
				const body = res && res.json && res.json.constructor === Function? 
					await res.json(): 
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

	cancel(abortController)
	{
		abortController && abortController.abort();
	}
}
