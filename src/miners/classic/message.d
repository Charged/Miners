// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.classic.message;

import miners.classic.interfaces;


class MessageLogger : public ClientMessageListener
{
public:
	const backlog = 20;

	char[][backlog] msgs;
	size_t cur;

	bool dirty;

	void delegate(char[]) message;

	char[][ubyte.max+1] players;

public:
	/*
	 *
	 * ClientMessageListener functions.
	 *
	 */


	void archive(byte id, char[] msg) { archive(msg); }

	void archive(char[] msg)
	{
		auto m = msgs[cur++] = escapeBad(msg.dup);
		if (cur >= msgs.length)
			cur = 0;

		doMessage(m);
	}

	void addPlayer(byte id, char[] name)
	{
		players[cast(ubyte)id] = name;
	}

	void removePlayer(byte id)
	{
		players[cast(ubyte)id] = null;
	}

	void removeAllPlayers()
	{
		players[0 .. $] = null;
	}


	/*
	 *
	 * Misc functions.
	 *
	 */


	void pushAll()
	{
		if (message is null)
			return;

		foreach(m; msgs[cur .. $])
			message(m);
		foreach(m; msgs[0 .. cur])
			message(m);
	}

	char[] getAllMessages()
	{
		char[(64+2)*backlog] tmp;
		size_t pos;

		foreach(m; msgs[cur .. $]) {
			tmp[pos .. pos + m.length] = m[0 .. $];
			pos += m.length;
			tmp[pos++] = '\n';
		}

		foreach(m; msgs[0 .. cur]) {
			tmp[pos .. pos + m.length] = m[0 .. $];
			pos += m.length;
			tmp[pos++] = '\n';
		}

		return tmp[0 .. pos].dup;
	}

protected:
	char[] escapeBad(char[] msg)
	{
		foreach(m; msg)
			if (m == '\0' || m == '\t' || m == '\n')
				m = ' ';
		return msg;
	}

	final void doMessage(char[] msg)
	{
		if (message !is null)
			message(msg);
	}
}
