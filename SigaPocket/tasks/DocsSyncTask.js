import Util from '../components/Util';
import SigaApi from '../components/SigaApi';
import AsyncStorage from '@react-native-async-storage/async-storage';

let last = null;

const DocsSyncTask = async (params) =>
{
	const loadUser = async () =>
	{
		const username = await AsyncStorage.getItem('@username');
		const password = await AsyncStorage.getItem('@password');
		return {username, password};
	};

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

	if(Util.compare(last, groups))
	{
		console.log('Grupos não atualizados');
		return;
	}

	last = groups;
	console.log('Grupos atualizados!');
	console.log(groups);
};


export default DocsSyncTask;