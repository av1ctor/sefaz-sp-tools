import React, {PureComponent} from 'react';
import PropTypes from 'prop-types';
import {SafeAreaView, ScrollView} from 'react-native';
import {List, Text} from 'react-native-paper';
import styles from './styles/default';

export default class Groups extends PureComponent
{
    static propTypes = {
        api: PropTypes.object.isRequired,
        showMessage: PropTypes.func.isRequired,
        navigation: PropTypes.object.isRequired,
        route: PropTypes.object,
    };

    constructor(props)
    {
        super(props);

        this.state = {
            groups: []
        };
    }

    async componentDidMount()
    {
        const groups = await this.props.api.loadGroups();
        this.setState({
            groups: groups
        });
    }

    renderGroup(group)
    {
        const docs = group.grupoDocs || [];
        if(docs.length === 0)
        {
            return null;
        }

        return (
            <List.Item 
                key={group.grupo}
                title={
                    <Text>
                        {group.grupoNome + ` (${docs.length})`}
                    </Text>
                } 
                id={group.grupo}
                left={props => <List.Icon {...props} icon="folder" />}
                onPress={() => this.props.navigation.navigate('Docs', {group: group})}>
            </List.Item>
        );
    }

    render()
    {
        const {groups} = this.state;

        return(
            <SafeAreaView style={styles.safeAreaView}>
                <ScrollView style={styles.scrollView}>
                    {groups.map(group => this.renderGroup(group))}
                </ScrollView>              
            </SafeAreaView>
        );
    }
}