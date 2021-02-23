
import equal from 'fast-deep-equal/react';

export default class Util
{
	static compare(v1, v2)
	{
		return equal(v1, v2);
	}
}