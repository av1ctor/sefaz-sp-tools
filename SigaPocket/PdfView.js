import React, {PureComponent} from 'react';
import PropTypes from 'prop-types';
import {StyleSheet, Dimensions, View} from 'react-native';
import {Text} from 'react-native-paper';
import Pdf from 'react-native-pdf';
import styles from './styles/default';

export default class PdfView extends PureComponent
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
            url: null,
            completed: 0.0
        };
    }

    handleProgress = (completed) =>
    {
        this.setState({
            completed: completed
        });
    }

    async componentDidMount()
    {
        const {doc} = this.props.route.params;
        const res = await this.props.api.loadPdf(doc.sigla, false, this.handleProgress);
        if(res === null)
        {
            this.props.showMessage('Falha ao carregar PDF', 'error');
            return;
        }

        this.setState({
            url: res,
            completed: 1.0
        });
    }

    render()
    {
        const {url, completed} = this.state;

        return(
            <View style={styles.pdfContainer}>
                {url &&  
                    <Pdf
                        source={{uri: url, cache: true}}
                        style={localStyles.pdf}
                    />
                }
                {!url && 
                    <Text>
                        Gerando: {(completed * 100).toFixed(0)}%
                    </Text>
                }
            </View>
        );
    }
}

const localStyles = StyleSheet.create({
    pdf: {
        flex:1,
        width:Dimensions.get('window').width,
        height:Dimensions.get('window').height,
    }
});