/**
 * @format
 * @flow strict-local
 */

import React, {PureComponent} from 'react';
import {createStackNavigator} from '@react-navigation/stack';
import SigaApi from './components/SigaApi';
import Logon from './Logon';
import Docs from './Docs';

const Stack = createStackNavigator();

export default class Main extends PureComponent
{
	constructor(props)
	{
		super(props);

		this.api = new SigaApi();
	}

	showMessage(msg, kind)
	{
		alert(msg);
	}

	render()
	{
		return (
			<>
				<Stack.Navigator initialRouteName="Logon">
					<Stack.Screen
        				name="Logon"
        				options={{ headerTitle: 'Logon' }}
      				>
						{props => 
							<Logon 
								{...props} 
								api={this.api} 
								showMessage={this.showMessage} 
							/>
						}
					</Stack.Screen>
      				<Stack.Screen
        				name="Docs"
        				options={{ headerTitle: 'Documentos' }}
      				>
						{props => 
							<Docs 
								{...props} 
								api={this.api} 
								showMessage={this.showMessage} 
							/>
						}
					</Stack.Screen>
				</Stack.Navigator>
			</>
		);
	}
};