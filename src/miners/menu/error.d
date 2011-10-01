// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.menu.error;

import std.string;

import charge.charge;
import charge.game.gui.textbased;

import miners.menu.base;
import miners.menu.runner;


class ErrorMenu : public MenuBase
{
private:
	Text te;
	Button qb;

	const char[] header = `Charged Miners`;

public:
	this(MenuRunner mr, char[] errorText, Exception e)
	{
		super(mr, header);

		te = new Text(this, 0, 0, errorText);

		// And some extra info if we get a Exception.
		if (e !is null) {
			auto t = format(e.classinfo.name, " ", e);
			te = new Text(this, 0, te.h + 8, t);
		}

		// Add a quit button at the bottom.
		qb = new Button(this, 0, te.y + te.h + 8, "Quit", 8);
		qb.pressed ~= &mr.commonMenuQuit;

		repack();

		auto center = plane.w / 2;

		// Center the children
		foreach(c; getChildren) {
			c.x = center - c.w/2;
		}
	}
}
