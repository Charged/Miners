// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.menu.list;

import charge.charge;
import charge.game.gui.textbased;
import charge.game.gui.input;

import miners.types;
import miners.interfaces;
import miners.menu.base;


const char[] header = `Classic`;
const uint childHeight = 424;
const uint childWidth = 9*16;


class ClassicServerListMenu : public MenuBase
{
private:
	ListView lv;

	const char[] header = `Classic`;

public:
	this(Router r, ClassicServerInfo[] csis)
	{
		super(r, header, Buttons.QUIT);

		lv = new ListView(this, 0, 0, csis);
		replacePlane(lv);

		repack();
	}
}

class ListView : public Container
{
private:
	Router r;
	Text text;

	int start;
	ClassicServerInfo[] csis;

public:
	this(ClassicServerListMenu cm, int x, int y, ClassicServerInfo[] csis)
	{
		// Parent needs to be null
		super(null, x, y, 424, 9*16);

		this.r = r;
		this.csis = csis;
		this.text = new Text(this, 0, 0, "");

		serverList(csis);
	}

	void repack()
	{
		text.x = (w - text.w) / 2;
		text.y = (h - text.h) / 2;
	}

protected:
	void serverList(ClassicServerInfo[] csis)
	{

		//foreach(int i, c; csis) {
		//	const string = "fCraft.net Freebuild [ENG]";
		//
		//	if (c.webName.length != string.length)
		//		continue;
		//
		//	if (c.webName != string)
		//		continue;
		//
		//	r.menu.getClassicServerInfoAndConnect(c);
		//}

		string t;
		foreach(int i, c; csis[start .. $]) {
			if (i > 7)
				break;

			t ~= c.webName ~ "\n\n";
		}

		text.setText(t.dup);
		repack();
	}
}
