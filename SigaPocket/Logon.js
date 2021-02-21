/**
 * @format
 * @flow strict-local
 */

import React, {PureComponent} from 'react';
import PropTypes from 'prop-types';
import {Image, View} from 'react-native';
import {Button, Text, TextInput} from 'react-native-paper';
import styles from './styles/default';

export default class Logon extends PureComponent
{
    static propTypes = {
        api: PropTypes.object.isRequired,
        showMessage: PropTypes.func.isRequired,
		navigation: PropTypes.object.isRequired,
    };

	constructor(props)
	{
		super(props);

		const vars = JSON.parse((process.env['REACT_VARS'] || '').replace(/'/g, '"') || '{}');

		this.state = {
			username: vars.username || '',
			password: vars.password || ''
		};
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
			this.props.showMessage('CPF ou matrícula obrigatório', 'error');
			return false;
		}
		
		if(!password)
		{
			this.props.showMessage('Senha obrigatória', 'error');
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
		
		const res = await this.props.api.logon(username, password);
		if(res.errors !== null)
		{
			this.props.showMessage(res.errors, 'error');
			return;
		}

		this.props.navigation.navigate('Docs');
	}

	render()
	{
		return (
			<>
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
			</>
		);
	}
};

