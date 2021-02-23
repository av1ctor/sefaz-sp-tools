import React from 'react';
import PropTypes from 'prop-types';
import {SafeAreaView, ScrollView, View} from 'react-native';
import {Badge, Button, Text, TextInput} from 'react-native-paper';
import styles from '../styles/default';

const Doc = ({navigation, route}) =>
{
	const renderStates = (states) =>
	{
		return (
			<Badge size={20}>
				{states.map(state => state.nome)}
			</Badge>
		);
	};


	const viewPdf = (doc) =>
	{
		navigation.navigate('PdfView', {doc: doc});
	};

	const {doc} = route.params;

	return(
		<SafeAreaView style={styles.safeAreaView}>
			<ScrollView style={styles.scrollView}>
				<View style={styles.view}>
					<TextInput
						label="Sigla"
						value={doc.sigla}
						editable={false}
					/>
				</View>
				<View style={styles.view}>
					<TextInput
						label="Descrição"
						value={doc.descr}
						editable={false}
						multiline
					/>
				</View>
				<View style={styles.view}>
					<TextInput
						label="Origem"
						value={doc.origem}
						editable={false}
					/>
				</View>
				<View style={styles.view}>
					<TextInput
						label="Tempo"
						value={doc.tempoRelativo}
						editable={false}
					/>
				</View>
				<View style={styles.view}>
					<Text>{renderStates(doc.list || [])}</Text>
				</View>
				<View style={styles.view}>
					<Button
						mode="contained"
						icon="eye-outline"
						onPress={() => viewPdf(doc)}
					>
						<Text style={{color: '#fff'}}>Visualizar</Text>
					</Button>
				</View>
			</ScrollView>              
		</SafeAreaView>
	);
};

Doc.propTypes = {
	navigation: PropTypes.object,
	route: PropTypes.object
};

export default Doc;