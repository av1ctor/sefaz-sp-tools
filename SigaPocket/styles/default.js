import {StyleSheet} from 'react-native';

const styles = StyleSheet.create({
	safeAreaView: {
		flex: 1
	},
	scrollView: {
		margin: 10,
	},
	body: {
		backgroundColor: '#fff',
	},
	logo: {
		width: 120,
		height: 55,
		resizeMode: 'center',
		alignSelf: 'center'
	},
	view: {
		paddingTop: 4,
	},
	pdfContainer: {
        flex: 1,
        justifyContent: 'flex-start',
        alignItems: 'center',
        marginTop: 25,
    }	
});

export default styles;