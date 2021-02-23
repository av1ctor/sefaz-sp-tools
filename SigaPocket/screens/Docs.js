import React from 'react';
import PropTypes from 'prop-types';
import {SafeAreaView, ScrollView} from 'react-native';
import {List} from 'react-native-paper';
import styles from '../styles/default';

const Docs = ({navigation, route}) =>
{
	const renderDoc = (doc) =>
	{
		return (
			<List.Item
				key={doc.codigo}
				title={doc.sigla}
				description={doc.descr}
				left={props => <List.Icon {...props} icon="file-document" />}
				onPress={() => navigation.navigate('Doc', {doc: doc})}
			/>
		);
	};

	const {group} = route.params;

	return(
		<SafeAreaView style={styles.safeAreaView}>
			<ScrollView style={styles.scrollView}>
				{(group.grupoDocs || []).map(doc => renderDoc(doc))}
			</ScrollView>              
		</SafeAreaView>
	);
};

Docs.propTypes = {
	navigation: PropTypes.object,
	route: PropTypes.object
};

export default Docs;