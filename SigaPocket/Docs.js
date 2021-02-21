import React, {PureComponent} from 'react';
import PropTypes from 'prop-types';
import {SafeAreaView, ScrollView} from 'react-native';
import {List} from 'react-native-paper';
import styles from './styles/default';

export default class Docs extends PureComponent
{
    static propTypes = {
        api: PropTypes.object.isRequired,
        showMessage: PropTypes.func.isRequired,
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

    renderDoc(doc)
    {
        return (
            <List.Item
                title={doc.sigla}
                description={doc.descr}
                left={props => <List.Icon {...props} icon="folder" />}
            />
        );
    }

    renderGroup(group)
    {
        const docs = group.grupoDocs || [];
        return (
            <List.Accordion 
                title={group.grupoNome + ` (${docs.length})`} 
                id={group.grupo}>
                {docs.map(doc => this.renderDoc(doc))}
            </List.Accordion>
        );
    }

    render()
    {
        const {groups} = this.state;

        return(
            <SafeAreaView style={styles.safeAreaView}>
                <ScrollView style={styles.scrollView}>
                    <List.AccordionGroup>
                        {groups.map(group => this.renderGroup(group))}
                    </List.AccordionGroup>
                </ScrollView>              
            </SafeAreaView>
        );
    }
}