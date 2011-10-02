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
	Text te[];
	Button button;

	const char[] header = `Charged Miners`;

public:
	this(MenuRunner mr, char[][] errorTexts, bool panic)
	{
		super(mr, header);

		int pos;
		te.length = errorTexts.length;

		foreach(uint i, t; errorTexts) {
			te[i] = new Text(this, 0, pos, t);
			pos += te[i].h + 8;
		}

		// Add a quit button at the bottom.
		if (panic) {
			button = new Button(this, 0, pos, "Quit", 8);
			button.pressed ~= &mr.commonMenuQuit;
		} else {
			button = new Button(this, 0, pos, "Ok", 8);
			button.pressed ~= &mr.commonMenuBack;
		}

		repack();

		auto center = plane.w / 2;

		// Center the children
		foreach(c; getChildren) {
			c.x = center - c.w/2;
		}
	}
}
