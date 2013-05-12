// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.menu.main;

import charge.charge;
import charge.game.gui.textbased;

import miners.options;
import miners.interfaces;
import miners.menu.base;


class MainMenu : MenuRunnerBase
{
private:
	Text te;
	Button classicButton;
	Button be;
	Button closeButton;
	Button quitButton;

	const string header = `Charged Miners`;

	const string text =
`Welcome to charged miners, please select below.

`;

public:
	this(Router r, Options opts)
	{
		auto menu = new MenuBase(header);
		int pos;

		super(r, opts, menu);

		te = new Text(menu, 0, 0, text);
		pos += te.h;
		classicButton = new Button(menu, 0, pos, "Classic", 32);
		pos += classicButton.h;
		pos += 16;
		closeButton = new Button(menu, 0, pos, "Close", 8);
		quitButton = new Button(menu, 0, pos, "Quit", 8);

		classicButton.pressed ~= &classic;
		closeButton.pressed ~= &back;
		quitButton.pressed ~= &quit;

		menu.repack();

		auto center = menu.plane.w / 2;

		// Center the children
		foreach(c; menu.getChildren) {
			c.x = center - c.w/2;
		}

		// Place the buttons next to each other.
		closeButton.x = center + 8;
		quitButton.x = center - 8 - quitButton.w;
	}

private:
	void classic(Button b) { r.loadLevelClassic(null); r.deleteMe(this); }
	void back(Button b) { r.deleteMe(this); }
	void quit(Button b) { r.quit(); r.deleteMe(this); }
}
