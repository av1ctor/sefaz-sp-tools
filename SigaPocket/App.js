/**
 * @format
 * @flow strict-local
 */

import React, {Component} from 'react';
import {Button, SafeAreaView, StyleSheet, ScrollView, View, Text, TextInput, StatusBar} from 'react-native';
import SigaApi from './components/SigaApi';

const InputWithLabel = ({label, children}) =>
{
	return (
		<>
			<View style={styles.inputContainer}>
				<View>
					<Text style={styles.inputLabel}>{label}</Text>
					{children}
				</View>
			</View>
		</>
	);
}

export default class App extends Component
{
	constructor(props)
	{
		super(props);

		this.state = {
			username: 'SFP29784',
			password: 'Spsempapel00'
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
								<Text style={styles.sectionTitle}>Logon</Text>

								<InputWithLabel label="Usuário">
									<TextInput
										style={styles.input}
										placeholder="Digite seu CPF ou matrícula"
										onChangeText={this.setUsername}
										value={this.state.username}
									/>
								</InputWithLabel>

								<InputWithLabel label="Senha">
									<TextInput
										style={styles.input}
										placeholder="Senha"
										onChangeText={this.setPassword}
										value={this.state.password}
									/>
								</InputWithLabel>

								<View style={styles.buttonContainer}>
									<Button
										style={styles.button}
										title="Entrar"
										onPress={this.doLogon}
									/>
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
	sectionTitle: {
		fontSize: 24,
		fontWeight: '600',
		color: '#000',
	},
	input: {
		borderColor: '#aaa',
		borderWidth: 1,
		borderRadius: 8,
	},
	inputContainer: {
		paddingTop: 8
	},
	inputLabel: {
		fontSize: 14,
		fontWeight: '700',
	},
	buttonContainer: {
		paddingTop: 16,
	},
	button: {
	},
	footer: {
		color: '#555',
		fontSize: 12,
		fontWeight: '600',
		padding: 4,
		paddingRight: 12,
		textAlign: 'right',
	},
});
