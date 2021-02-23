import React, {useReducer, createContext} from 'react';
import PropTypes from 'prop-types';

export const UserContext = createContext();

const initState = {
	user: {}
};

const reducer = (state, action) => 
{
	switch(action.type) 
	{
	case 'SET_USER':
		return {
			user: action.payload
		};

	default:
		throw new Error();
	}
};

export const UserContextProvider = (props) => 
{
	const [state, dispatch] = useReducer(reducer, initState);

	return (
		<UserContext.Provider 
			value={[state, dispatch]}>
			{props.children}
		</UserContext.Provider>
	);
};

UserContextProvider.propTypes = {
	children: PropTypes.any
};