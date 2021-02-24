/**
 * @format
 * @flow strict-local
 */

import React from 'react';
import PropTypes from 'prop-types';
import {createStackNavigator} from '@react-navigation/stack';
import Logon from './screens/Logon';
import Groups from './screens/Groups';
import Docs from './screens/Docs';
import Doc from './screens/Doc';
import PdfView from './screens/PdfView';

const Stack = createStackNavigator();

const Main = ({api}) =>
{
	const showMessage = (msg, kind) =>
	{
		alert(msg);
	};

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
							api={api} 
							showMessage={showMessage} 
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
							api={api} 
							showMessage={showMessage} 
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
							api={api} 
							showMessage={showMessage} 
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
							api={api} 
							showMessage={showMessage} 
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
							api={api} 
							showMessage={showMessage} 
						/>
					}
				</Stack.Screen>
			</Stack.Navigator>
		</>
	);
};

Main.propTypes = {
	api: PropTypes.object
};

export default Main;