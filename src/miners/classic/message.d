// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.classic.message;

import std.string : tolower;

import miners.classic.interfaces;
import miners.importer.network : removeColorTags;


class MessageLogger : ClassicClientMessageListener
{
public:
	const backlog = 100;

	string[backlog] msgs;
	size_t cur;

	bool dirty;

	void delegate(string) message;

	string[ubyte.max+1] tabs;
	string[ubyte.max+1] players;

public:
	/*
	 *
	 * ClassicClientMessageListener functions.
	 *
	 */


	void archive(byte id, string msg) { archive(msg); }

	void archive(string msg)
	{
		auto m = msgs[cur++] = escapeBad(msg.dup);
		if (cur >= msgs.length)
			cur = 0;

		doMessage(m);
	}

	void addPlayer(byte id, string name)
	{
		tabs[cast(ubyte)id] = null;
		players[cast(ubyte)id] = name;

		if (name is null)
			return;

		tabs[cast(ubyte)id] = tolower(removeColorTags(name));
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


	string tabCompletePlayer(string searchIn, string lastIn)
	{
		auto search = tolower(searchIn);
		auto last = tolower(lastIn);
		bool next = lastIn is null; // If null just pick the first match
		int first = -1;

		foreach(int i, tab; tabs) {
			if (tab.length < search.length)
				continue;

			if (tab.length == 0)
				continue;

			if (tab[0 .. search.length] != search[0 .. $])
				continue;

			// Remmember the first match, for loop arounds
			if (first < 0)
				first = i;

			// Is this the player after the last player?
			if (next)
				return players[i];

			// If name is to short for last
			if (tab.length < last.length)
				continue;

			// Is this the last player?
			if (tab[0 .. last.length] == last[])
				next = true;
		}

		if (first >= 0)
			return players[first];
		else
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
