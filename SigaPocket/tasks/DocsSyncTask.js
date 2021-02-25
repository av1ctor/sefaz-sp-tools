import AsyncStorage from '@react-native-async-storage/async-storage';
import SigaApi from '../components/SigaApi';
import Notificator from '../components/Notificator';

const config = {
	groups: null,
	running: false
};

const CHANNEL_ID = 'siga-pocket-chan';

const DocsSyncTask = async (params) =>
{
	if(config.running)
	{
		return;
	}
	
	try
	{
		config.running = true;

		const loadUser = async () =>
		{
			const username = await AsyncStorage.getItem('@username');
			const password = await AsyncStorage.getItem('@password');
			return {username, password};
		};

		Notificator.config((msg) =>
		{
			AsyncStorage.setItem('@reloadGroups', '1');
		});

		const user = await loadUser();
		if(!user.username || !user.password)
		{
			console.error('Erro: sem nome/pwd de usuário');
			return;
		}

		const api = new SigaApi();	
		
		const res = await api.logon(user.username, user.password);
		if(res.errors !== null)
		{
			console.error('Erro: api.logon() falhou');
			return;
		}

		const groups = await api.loadGroups();
		if(!groups)
		{
			console.error('Erro: api.loadGroups() falhou');
			return;
		}

		if(api.compareGroups(config.groups, groups))
		{
			return;
		}

		const firstRun = config.groups === null;
		config.groups = groups;
		
		if(!firstRun)
		{
			Notificator.notify('Atualização ocorrida na mesa', CHANNEL_ID);
		}
	}
	finally
	{
		config.running = false;
	}
};


export default DocsSyncTask;