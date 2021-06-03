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

function csv2json(text)
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
					[keys[index]]: col.trim()
				}), 
				{})
			);
		}
	}

	return res;
}

module.exports = {sleep, memoize, lastDayOfMonth, dateToString, csv2json};
