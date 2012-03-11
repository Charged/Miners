// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.classic.message;


import miners.classic.interfaces;
import miners.importer.network;


class MessageLogger : public ClientMessageListener
{
public:
	const backlog = 20;

	char[][backlog] msgs;
	bool dirty;

public:
	this()
	{
		dirty = true;
	}

	void upLine()
	{
		for(int i = backlog-1, k = backlog-2; k >= 0; i--, k--)
			msgs[i] = msgs[k];
	}

	void message(byte id, char[] msg)
	{
		upLine();

		msgs[0] = escapeBad(removeColorTags(msg));
		dirty = true;
	}

	char[] getAllMessages()
	{
		char[(64+2)*backlog] tmp;
		size_t pos;

		foreach_reverse(m; msgs) {
			tmp[pos .. pos + m.length] = m[0 .. $];
			pos += m.length;
			tmp[pos++] = '\n';
		}
		return tmp[0 .. pos].dup;
	}


	static char[] escapeBad(char[] msg)
	{
		foreach(m; msg)
			if (m == '\0' || m == '\t' || m == '\n')
				m = ' ';
		return msg;
	}
}
