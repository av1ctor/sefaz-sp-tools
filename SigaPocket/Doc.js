import React, {PureComponent} from 'react';
import PropTypes from 'prop-types';
import {SafeAreaView, ScrollView, View} from 'react-native';
import {Badge, Button, Text, TextInput} from 'react-native-paper';
import styles from './styles/default';

export default class Doc extends PureComponent
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
	}

	renderStates(states)
	{
		return (
			<Badge size={20}>
				{states.map(state => state.nome)}
			</Badge>
		);
	}

	viewPdf(doc)
	{
		this.props.navigation.navigate('PdfView', {doc: doc});
	}

	render()
	{
		const {doc} = this.props.route.params;

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
						<Text>{this.renderStates(doc.list || [])}</Text>
					</View>
					<View style={styles.view}>
						<Button
							mode="contained"
							icon="eye-outline"
							onPress={() => this.viewPdf(doc)}
						>
							<Text style={{color: '#fff'}}>Visualizar</Text>
						</Button>
				   </View>
				</ScrollView>              
			</SafeAreaView>
		);
	}
}