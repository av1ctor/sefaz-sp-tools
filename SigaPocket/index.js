/**
 * @format
 */

import React from 'react';
import {AppRegistry} from 'react-native';
import {Provider as PaperProvider} from 'react-native-paper';
import Main from './Main';
import {name as appName} from './app.json';

export default function App() 
{
    return (
      <PaperProvider>
        <Main />
      </PaperProvider>
    );
}

AppRegistry.registerComponent(appName, () => App);
