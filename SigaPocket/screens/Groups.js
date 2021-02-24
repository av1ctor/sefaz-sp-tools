import React, {useContext, useEffect} from 'react';
import PropTypes from 'prop-types';
import {SafeAreaView, ScrollView} from 'react-native';
import {List, Text} from 'react-native-paper';
import {DocsContext} from '../contexts/Docs';
import Util from '../components/Util';
import styles from '../styles/default';

const Groups = ({api, showMessage, navigation}) =>
{
	const [state, dispatch] = useContext(DocsContext);

	useEffect(() => 
	{
		loadGroups();
		setInterval(() => loadGroups(false), 1000*60*1);
	}, []);

	let last = null;

	const loadGroups = async (firstRun = true) =>
	{
		const current = await api.loadGroups();
		if(!current)
		{
			if(!firstRun)
			{
				showMessage(['Erro ao carregar grupos de documentos'], 'error');
			}
			return;
		}

		if(!Util.compare(last, current))
		{
			last = current;
			dispatch({
				type: 'SET_GROUPS',
				payload: current || [],
			});
		}

	};

	const renderGroup = (group) =>
	{
		const cnt = group.grupoCounterAtivo;
		if(cnt === 0)
		{
			return null;
		}

		return (
			<List.Item 
				key={group.grupo}
				title={
					<Text>
						{group.grupoNome + ` (${cnt})`}
					</Text>
				} 
				id={group.grupo}
				left={props => <List.Icon {...props} icon="folder" />}
				onPress={() => navigation.navigate('Docs', {group: group})}>
			</List.Item>
		);
	};

	const {groups} = state;
		
	return (
		<SafeAreaView style={styles.safeAreaView}>
			<ScrollView style={styles.scrollView}>
				{groups.map(group => renderGroup(group))}
			</ScrollView>              
		</SafeAreaView>
	);
};

Groups.propTypes = {
	api: PropTypes.object,
	showMessage: PropTypes.func,
	navigation: PropTypes.object,
};

export default Groups;