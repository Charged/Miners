// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.menu.main;

import charge.charge;
import charge.game.gui.textbased;

import miners.options;
import miners.interfaces;
import miners.menu.base;


class MainMenu : public MenuRunnerBase
{
private:
	Text te;
	Button io;
	Button ra;
	Button cl;
	Button be;
	Button cb;
	Button qb;

	const string header = `Charged Miners`;

	const string text =
`Welcome to charged miners, please select below.

`;

public:
	this(Router r, Options opts)
	{
		auto mb = new MenuBase(header);
		int pos;

		super(r, opts, mb);

		te = new Text(mb, 0, 0, text);
		pos += te.h;
		io = new Button(mb, 0, pos, "Ion", 32);
		pos += io.h;
		ra = new Button(mb, 0, pos, "Random", 32);
		pos += ra.h;
		cl = new Button(mb, 0, pos, "Classic", 32);
		pos += cl.h;
		be = new Button(mb, 0, pos, "Beta", 32);
		pos += be.h + 16;
		cb = new Button(mb, 0, pos, "Close", 8);
		qb = new Button(mb, 0, pos, "Quit", 8);

		io.pressed ~= &ion;
		ra.pressed ~= &random;
		cl.pressed ~= &classic;
		be.pressed ~= &selectLevel;
		cb.pressed ~= &back;
		qb.pressed ~= &quit;

		mb.repack();

		auto center = mb.plane.w / 2;

		// Center the children
		foreach(c; mb.getChildren) {
			c.x = center - c.w/2;
		}

		// Place the buttons next to each other.
		cb.x = center + 8;
		qb.x = center - 8 - qb.w;
	}

private:
	void ion(Button b) { r.chargeIon(); r.deleteMe(this); }
	void random(Button b) { r.loadLevelModern(null); r.deleteMe(this); }
	void classic(Button b) { r.loadLevelClassic(null); r.deleteMe(this); }
	void selectLevel(Button b) { r.displayLevelSelector(); r.deleteMe(this); }
	void back(Button b) { r.deleteMe(this); }
	void quit(Button b) { r.quit(); r.deleteMe(this); }
}
