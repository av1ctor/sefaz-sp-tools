import React, {useState, useEffect} from 'react';
import PropTypes from 'prop-types';
import {StyleSheet, Dimensions, View} from 'react-native';
import {Text} from 'react-native-paper';
import Pdf from 'react-native-pdf';
import styles from '../styles/default';

const PdfView = ({api, showMessage, route}) =>
{
	const [url, setUrl] = useState(null);
	const [completed, setCompleted] = useState(0.0);

	useEffect(() =>
	{
		(async () =>
		{
			const {doc} = route.params;
			const res = await api.loadPdf(doc.sigla, false, (completed) => setCompleted(completed));
			if(res === null)
			{
				showMessage('Falha ao carregar PDF', 'error');
				return;
			}
    
			setUrl(res);
			setCompleted(1.0);
		})();
	}, []);

	return (
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
};

const localStyles = StyleSheet.create({
	pdf: {
		flex: 1,
		width: Dimensions.get('window').width,
		height: Dimensions.get('window').height,
	}
});

PdfView.propTypes = {
	api: PropTypes.object,
	showMessage: PropTypes.func,
	route: PropTypes.object,
};
export default PdfView;