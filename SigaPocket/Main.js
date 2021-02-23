/**
 * @format
 * @flow strict-local
 */

import React, {PureComponent} from 'react';
import {createStackNavigator} from '@react-navigation/stack';
import SigaApi from './components/SigaApi';
import Logon from './screens/Logon';
import Groups from './screens/Groups';
import Docs from './screens/Docs';
import Doc from './screens/Doc';
import PdfView from './screens/PdfView';

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
        				name="Groups"
        				options={{ headerTitle: 'Grupos' }}
      				>
						{props => 
							<Groups 
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
					<Stack.Screen
        				name="Doc"
        				options={{ headerTitle: 'Documento' }}
      				>
						{props => 
							<Doc 
								{...props} 
								api={this.api} 
								showMessage={this.showMessage} 
							/>
						}
					</Stack.Screen>
					<Stack.Screen
        				name="PdfView"
        				options={{ headerTitle: 'PDF' }}
      				>
						{props => 
							<PdfView 
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