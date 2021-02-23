/**
 * @format
 * @flow strict-local
 */

import React, {useContext, useState} from 'react';
import PropTypes from 'prop-types';
import {Image, View, SafeAreaView, ScrollView} from 'react-native';
import {Button, Text, TextInput} from 'react-native-paper';
import styles from '../styles/default';
import {UserContext} from '../contexts/User';

const vars = JSON.parse(
	(process.env.NODE_ENV === 'development'? process.env.REACT_VARS || '': '')
		.replace(/'/g, '"') || 
	'{}');

const Logon = ({api, showMessage, navigation}) =>
{
	const [username, setUsername] = useState(vars.username || '');
	const [password, setPassword] = useState(vars.password || '');
	const [state, dispatch] = useContext(UserContext);

	const validateForm = () =>
	{
		if(!username)
		{
			showMessage('CPF ou matrícula obrigatório', 'error');
			return false;
		}
		
		if(!password)
		{
			showMessage('Senha obrigatória', 'error');
			return false;
		}

		return true;
	};


	const doLogon = async () =>
	{
		if(!validateForm())
		{
			return;
		}
		
		const res = await api.logon(username, password);
		if(res.errors !== null)
		{
			showMessage(res.errors, 'error');
			return;
		}

		dispatch({
			type: 'SET_USER',
			payload: res.data
		});

		navigation.navigate('Groups');
	};

	return (
		<SafeAreaView style={styles.safeAreaView}>
			<ScrollView style={styles.scrollView}>
				<View style={styles.view}>
					<Image 
						style={styles.logo}
						source={require('../assets/logo-sem-papel-cor.png')}
					/>
				</View>

				<View style={styles.view}>
					<TextInput
						label="Usuário"
						placeholder="Digite seu CPF ou matrícula"
						onChangeText={setUsername}
						value={state.username}
					/>
				</View>

				<View style={styles.view}>
					<TextInput
						secureTextEntry
						label="Senha"
						placeholder="Senha"
						onChangeText={setPassword}
						value={state.password}
					/>
				</View>

				<View style={styles.view}>
					<Button
						mode="contained"
						icon="login"
						onPress={doLogon}
					>
						<Text style={{color: '#fff'}}>Entrar</Text>
					</Button>
				</View>
			</ScrollView>
		</SafeAreaView>
	);
};

Logon.propTypes = {
	api: PropTypes.object,
	showMessage: PropTypes.func,
	navigation: PropTypes.object,
};

export default Logon;