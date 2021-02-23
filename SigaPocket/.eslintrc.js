module.exports = {
	'env': {
		'browser': true,
		'es6': true
	},
	'extends': [
		'eslint:recommended',
		'plugin:react/recommended'
	],
	'globals': {
		'Atomics': 'readonly',
		'SharedArrayBuffer': 'readonly'
	},
	'parser': 'babel-eslint',
	'parserOptions': {
		'ecmaVersion': 6,
		'sourceType': 'module',
		'ecmaFeatures': {
			'jsx': true,
			'modules': true,
			'experimentalObjectRestSpread': true
		}
	},    
	'plugins': [
		'react'
	],
	'rules': {
		'jsx-a11y/anchor-is-valid': 0,
		'comma-dangle': 0,
		'react/jsx-uses-vars': 1,
		'react/display-name': 1,
		'no-unused-vars': 'warn',
		'no-console': 1,
		'no-unexpected-multiline': 'warn',        
		'indent': [
			'warn',
			'tab'
		],
		'linebreak-style': [
			'warn',
			'windows'
		],
		'quotes': [
			'warn',
			'single'
		],
		'semi': [
			'warn',
			'always'
		]
	}
};