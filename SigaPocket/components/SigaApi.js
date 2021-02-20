
const ROOT_PATH = 'https://www.documentos.spsempapel.sp.gov.br';
const BASE_PATH = ROOT_PATH + '/sigaex/app/';
const LOGIN_URL = ROOT_PATH + '/siga/public/app/login';

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
				return {errors: ['Usuário e/ou senha inválidos'], data: null}
			}
		}
		else if(res.status !== 302)
		{
			return {errors: ['Usuário e/ou senha inválidos'], data: null}
		}

		return res;
	}

	loadDocs()
	{
		const data = new FormData();
		data.append('exibeLotacao', true);
		data.append('trazerAnotacoes', true);
		data.append('trazerComposto', true);
		data.append('trazerArquivados', false);
		data.append('trazerCancelados', false);
		data.append('ordemCrescenteData', true);
		data.append('idVisualizacao', 0);
		
		return this.post('mesa2.json', data);
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
				cache: 'no-store',
				credentials: 'include',
				method: method,
				signal: abortController && abortController.signal
			};

			if(data !== null)
			{
				options.body = !isJsonRequest? data: JSON.stringify(data);
			}

			let errors = null;
			const response = await fetch(url, options)
				.catch((e) => errors = e);

			if(errors === null && response && response.ok)
			{
				try
				{
					const body = isJsonResponse? await response.json(): await response.text();
					return {errors: null, data: body, status: response.status};
				}
				catch(e)
				{
					return {errors: [e.message], data: null};
				}
			}
			else
			{
				const body = response && response.json && response.json.constructor === Function? 
					await response.json(): 
					null;
				
				return {errors: errors || [], data: body, status: response && response.status};
			}
		}
		catch (e)
		{
			return {errors: [e.message], data: null};
		}

	}

	async get(path, options = {})
	{
		return await this.requestURL('GET', BASE_PATH + path, null, options);
	}

	async post(path, data, options = {})
	{
		return await this.requestURL('POST', BASE_PATH + path, data, options);
	}

	async put(path, data, options = {})
	{
		return await this.requestURL('PUT', BASE_PATH + path, data, options);
	}

	async patch(path, data, options = {})
	{
		return await this.requestURL('PATCH', BASE_PATH + path, data, options);
	}

	async del(path, options = {})
	{
		return await this.requestURL('DELETE', BASE_PATH + path, null, options);
	}

	cancel(abortController)
	{
		abortController && abortController.abort();
	}
}
