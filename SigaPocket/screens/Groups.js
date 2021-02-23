import React, {useContext, useEffect} from 'react';
import PropTypes from 'prop-types';
import {SafeAreaView, ScrollView} from 'react-native';
import {List, Text} from 'react-native-paper';
import styles from '../styles/default';
import {DocsContext} from '../contexts/Docs';

const Groups = ({api, showMessage, navigation}) =>
{
	const [state, dispatch] = useContext(DocsContext);

	useEffect(() => 
	{
		(async () => 
		{
			const groups = await api.loadGroups();
			if(!groups)
			{
				showMessage(['Erro ao carregar grupos de documentos'], 'error');
			}

			dispatch({
				type: 'SET_GROUPS',
				payload: groups || [],
			});
		}
		)();
	}, []);

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