import React, {PureComponent} from 'react';
import PropTypes from 'prop-types';
import {SafeAreaView, ScrollView} from 'react-native';
import {List} from 'react-native-paper';
import styles from '../styles/default';

export default class Docs extends PureComponent
{
    static propTypes = {
        api: PropTypes.object.isRequired,
        showMessage: PropTypes.func.isRequired,
        navigation: PropTypes.object.isRequired,
        route: PropTypes.object,
    };

    renderDoc(doc)
    {
        return (
            <List.Item
                key={doc.codigo}
                title={doc.sigla}
                description={doc.descr}
                left={props => <List.Icon {...props} icon="file-document" />}
                onPress={() => this.props.navigation.navigate('Doc', {doc: doc})}
            />
        );
    }

    render()
    {
        const {group} = this.props.route.params;

        return(
            <SafeAreaView style={styles.safeAreaView}>
                <ScrollView style={styles.scrollView}>
                    {(group.grupoDocs || []).map(doc => this.renderDoc(doc))}
                </ScrollView>              
            </SafeAreaView>
        );
    }
}