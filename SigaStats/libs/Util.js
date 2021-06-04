const iconv = require('iconv-lite');

function sleep(ms) 
{
	return new Promise((resolve) => 
	{
	  setTimeout(resolve, ms);
	});
  } 

function memoize(method, options = {ttl: null}) 
{
	const values = new Map();
	const times = new Map();
    
	return async function() 
	{
		const key = JSON.stringify(arguments);
		const exists = values.has(key);
		const valid = exists && (!options.ttl || Date.now() <= times.get(key) + options.ttl);

		const value = valid? 
			values.get(key): 
			method.apply(this, arguments);
		
		if(!valid)
		{
			values.set(key, value);
			times.set(key, Date.now());
		}
		
		return value;
	};
}

function lastDayOfMonth(year, month)
{
	return new Date(year, month + 1, 0);
}

function dateToString(date)
{
	return ('0' + date.getDate()).slice(-2) + '/'
		+ ('0' + (date.getMonth()+1)).slice(-2) + '/'
		+ date.getFullYear();
}

function clearDups(arr)
{
	return arr.map((item, index) => arr.indexOf(item) === index? item: item + '2');
}

function csv2json(text, keysToKeep = null)
{
	const res = [];

	const rows = text.split('\n');
	const keys = clearDups(rows[1].split(';'));

	for(let i = 2; i < rows.length; i++)
	{
		const row = rows[i];
		if(row)
		{
			const cols = row.substr(0, row.length - 1).split(';');
			res.push(
				cols.reduce((obj, col, index) => ({
					...obj, 
					[keys[index]]: !keysToKeep || keysToKeep.indexOf(keys[index]) !== -1? 
						col.trim():
						undefined
				}), 
				{})
			);
		}
	}

	return res;
}

function objectsToCsv(objs)
{
    let res = '';
    
    if(objs && objs.length > 0)
    {
        res += Object.keys(objs[0]).join(';') + '\n';
        res += objs.map(obj => Object.values(obj).map(val => `"${val}"`).join(';')).join('\n');
    }

    return iconv.encode(res, 'latin1');
}

function array2map(arr, keys, keyToRename = null)
{
	return arr.reduce((map, item) => 
	{
		const key = keys.reduce((res, k) => res + (item[k] || ''), '');
		map.set(
			key, 
			!keyToRename?
				item: 
				{
					...item, 
					[keyToRename.to]: item[keyToRename.from],
					[keyToRename.from]: undefined
				});
		
		return map;
	}, new Map());
}

module.exports = {sleep, memoize, lastDayOfMonth, dateToString, csv2json, objectsToCsv, array2map};
