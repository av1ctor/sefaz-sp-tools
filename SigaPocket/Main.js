/**
 * @format
 * @flow strict-local
 */

import React, {Component} from 'react';
import {Image, SafeAreaView, StyleSheet, ScrollView, View, StatusBar} from 'react-native';
import {Button, Text, TextInput} from 'react-native-paper';
import SigaApi from './components/SigaApi';

export default class App extends Component
{
	constructor(props)
	{
		super(props);

		const vars = JSON.parse((process.env['REACT_VARS'] || '').replace(/'/g, '"') || '{}');

		this.state = {
			username: vars.username || '',
			password: vars.password || ''
		};

		this.api = new SigaApi();
	}

	setUsername = (text) =>
	{
		this.setState({
			username: text
		});
	}

	setPassword = (text) =>
	{
		this.setState({
			password: text
		});
	}

	showMessage(msg, kind)
	{
		alert(msg);
	}

	validateForm()
	{
		const {username, password} = this.state;
		if(!username)
		{
			this.showMessage('CPF ou matrícula obrigatório', 'error');
			return false;
		}
		
		if(!password)
		{
			this.showMessage('Senha obrigatória', 'error');
			return false;
		}

		return true;
	}


	doLogon = async () =>
	{
		if(!this.validateForm())
		{
			return;
		}
		
		const {username, password} = this.state;
		
		const res = await this.api.logon(username, password);
		if(res.errors !== null)
		{
			this.showMessage(res.errors, 'error');
			return;
		}

		this.showMessage('Sucesso!', 'success');

		const docs = await this.api.loadDocs();
		console.log(docs);
	}

	render()
	{
		return (
			<>
				<StatusBar barStyle="dark-content" />
				<SafeAreaView>
					<ScrollView
						contentInsetAdjustmentBehavior="automatic"
						style={styles.scrollView}>
						<View style={styles.body}>
							<View style={styles.sectionContainer}>
								<View style={styles.view}>
									<Image 
										style={styles.logo}
										source={require('./assets/logo-sem-papel-cor.png')}
									/>
								</View>

								<View style={styles.view}>
									<TextInput
										label="Usuário"
										placeholder="Digite seu CPF ou matrícula"
										onChangeText={this.setUsername}
										value={this.state.username}
									/>
								</View>

								<View style={styles.view}>
									<TextInput
										secureTextEntry
										label="Senha"
										placeholder="Senha"
										onChangeText={this.setPassword}
										value={this.state.password}
									/>
								</View>

								<View style={styles.view}>
									<Button
										mode="contained"
										icon="login"
										onPress={this.doLogon}
									>
										<Text style={{color: '#fff'}}>Entrar</Text>
									</Button>
								</View>
							</View>

						</View>
					</ScrollView>
				</SafeAreaView>
			</>
		);
	}
};

const styles = StyleSheet.create({
	scrollView: {
		backgroundColor: '#ccc',
	},
	body: {
		backgroundColor: '#fff',
	},
	sectionContainer: {
		marginTop: 32,
		paddingHorizontal: 24,
	},
	logo: {
		width: 120,
		height: 55,
		resizeMode: 'center',
		alignSelf: 'center'
	},
	view: {
		paddingTop: 4,
	},
});
