// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.menu.main;

import charge.charge;
import charge.game.gui.textbased;

import miners.menu.base;
import miners.menu.runner;


class MainMenu : public MenuBase
{
private:
	Text te;
	Button ra;
	Button cl;
	Button be;
	Button cb;
	Button qb;

	const char[] header = `Charged Miners`;

	const char[] text =
`Welcome to charged miners, please select below.

`;

public:
	this(MenuRunner mr)
	{
		int pos;

		super(mr, header);

		te = new Text(this, 0, 0, text);
		pos += te.h;
		ra = new Button(this, 0, pos, "Random", 32);
		pos += ra.h;
		cl = new Button(this, 0, pos, "Classic", 32);
		pos += cl.h;
		be = new Button(this, 0, pos, "Beta", 32);
		pos += be.h + 16;
		cb = new Button(this, 0, pos, "Close", 8);
		qb = new Button(this, 0, pos, "Quit", 8);

		ra.pressed ~= &mr.selectMenuSelect;
		cl.pressed ~= &mr.mainMenuClassic;
		be.pressed ~= &mr.mainMenuSelectLevel;
		cb.pressed ~= &mr.commonMenuClose;
		qb.pressed ~= &mr.commonMenuQuit;

		repack();

		auto center = plane.w / 2;

		// Center the children
		foreach(c; getChildren) {
			c.x = center - c.w/2;
		}

		// Place the buttons next to each other.
		cb.x = center + 8;
		qb.x = center - 8 - qb.w;
	}
}
