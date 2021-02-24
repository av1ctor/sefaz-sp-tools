/**
 * @format
 */

// SigaPocket - app para acesso ao Sem Papel (www.documentos.spsempapel.sp.gov.br)
// Copyright 2021 André Vicentini (avtvicentini)
// Licenciado sob GNU GPL-2.0-ou-posterior

import 'react-native-gesture-handler';
import React from 'react';
import {AppRegistry} from 'react-native';
import {Provider as PaperProvider} from 'react-native-paper';
import {NavigationContainer} from '@react-navigation/native';
import {UserContextProvider} from './contexts/User';
import {DocsContextProvider} from './contexts/Docs';
import SigaApi from './components/SigaApi';
import DocsSyncTask from './tasks/DocsSyncTask';
import Main from './Main';
import {name as appName} from './app.json';

const api = new SigaApi();

export default function App() 
{
	return (
		<UserContextProvider>
			<DocsContextProvider>
				<PaperProvider>
					<NavigationContainer>
						<Main api={api} />
					</NavigationContainer>
				</PaperProvider>
			</DocsContextProvider>
		</UserContextProvider>
	);
}

AppRegistry.registerHeadlessTask('DocsSyncTask', () => DocsSyncTask);
AppRegistry.registerComponent(appName, () => App);
