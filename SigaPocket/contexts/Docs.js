import React, {useReducer, createContext} from 'react';
import PropTypes from 'prop-types';

export const DocsContext = createContext();

const initState = {
	groups: []
};

const reducer = (state, action) =>
{
	switch(action.type)
	{
	case 'SET_GROUPS':
		return {
			groups: action.payload
		};

	default:
		throw new Error();
	}
};

export const DocsContextProvider = (props) =>
{
	const [state, dispatch] = useReducer(reducer, initState);
    
	return (
		<DocsContext.Provider 
			value={[state, dispatch]}>
			{props.children}
		</DocsContext.Provider>
	);
};

DocsContextProvider.propTypes = {
	children: PropTypes.any
};