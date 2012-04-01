// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.classic.message;

import std.string : tolower;

import miners.classic.interfaces;


class MessageLogger : public ClientMessageListener
{
public:
	const backlog = 20;

	char[][backlog] msgs;
	size_t cur;

	bool dirty;

	void delegate(char[]) message;

	char[][ubyte.max+1] tabs;
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
		tabs[cast(ubyte)id] = null;
		players[cast(ubyte)id] = name;

		if (name is null)
			return;

		if (name[0] == '&' && name.length > 2)
			name = name[2 .. $];

		tabs[cast(ubyte)id] = tolower(name);
	}

	void removePlayer(byte id)
	{
		tabs[cast(ubyte)id] = null;
		players[cast(ubyte)id] = null;
	}

	void removeAllPlayers()
	{
		tabs[0 .. $] = null;
		players[0 .. $] = null;
	}


	/*
	 *
	 * Misc functions.
	 *
	 */


	char[] tabCompletePlayer(char[] start)
	{
		auto search = tolower(start);
		int found = -1;

		foreach(int i, tab; tabs) {
			if (tab.length < search.length)
				continue;

			if (tab[0 .. search.length] != search[0 .. $])
				continue;

			// Don't return anything on multiple hits.
			if (found >= 0)
				return null;

			found = i;
		}

		if (found >= 0)
			return players[found];

		return null;
	}

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
