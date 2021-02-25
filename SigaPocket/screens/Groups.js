import React, {useContext, useEffect} from 'react';
import PropTypes from 'prop-types';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {SafeAreaView, ScrollView} from 'react-native';
import {List, Text} from 'react-native-paper';
import {DocsContext} from '../contexts/Docs';
import styles from '../styles/default';

const Groups = ({api, showMessage, navigation}) =>
{
	const [state, dispatch] = useContext(DocsContext);

	useEffect(() => 
	{
		loadGroups('useEffect()');		
	}, []);

	const config = {
		check: {
			timer: null,
			running: false
		},
		load: {
			groups: null,
			timer: null,
			running: false
		}
	};

	const checkIfReloadIsNeeded = async () =>
	{
		if(config.check.running)
		{
			return;
		}

		config.check.running = true;

		try
		{
			const reloadGroups = await AsyncStorage.getItem('@reloadGroups');
			if(reloadGroups)
			{
				await AsyncStorage.removeItem('@reloadGroups');
				loadGroups('checkIfReloadIsNeeded()');
			}
		}
		finally
		{
			config.check.running = false;
			config.check.timer && clearTimeout(config.check.timer);
			config.check.timer = setTimeout(() => checkIfReloadIsNeeded(), 1000*5);
		}
	};

	checkIfReloadIsNeeded();

	const loadGroups = async (by = 'unknown') =>
	{
		if(config.load.running)
		{
			return;
		}

		config.load.running = true;

		try
		{
			//console.log(`loadGroups() called by ${by}`);

			const groups = await api.loadGroups();
			if(!groups)
			{
				if(config.load.groups === null)
				{
					showMessage(['Erro ao carregar grupos de documentos'], 'error');
				}
			}
			else
			{
				if(!api.compareGroups(config.load.groups, groups))
				{
					config.load.groups = groups;
					dispatch({
						type: 'SET_GROUPS',
						payload: groups || [],
					});
				}
			}
		}
		finally
		{
			config.load.running = false;
			config.load.timer && clearTimeout(config.load.timer);
			config.load.timer = setTimeout(() => loadGroups('loadGroups()'), 1000*60*1);
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