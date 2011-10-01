// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.menu.beta;

import charge.charge;
import charge.math.ints;
import charge.game.gui.textbased;

import miners.menu.base;
import miners.menu.runner;
import miners.importer.info;


class LevelMenu : public MenuBase
{
private:
	Text te;
	LevelSelector ls;
	Button ba;

	const char[] header = `Select a level`;

	const char[] text =
`Welcome to charged miners, please select level below.

`;

public:
	this(MenuRunner mr)
	{
		super(mr, header);

		te = new Text(this, 0, 0, text);
		ls = new LevelSelector(this, 0, te.h, &mr.selectMenuSelect);
		ba = new Button(this, 0, ls.y + ls.h + 16, "Back", 8);

		ba.pressed ~= &mr.selectMenuBack;

		repack();

		auto center = plane.w / 2;

		// Center the children
		foreach(c; getChildren) {
			c.x = center - c.w/2;
		}
	}
}

/**
 * A Container for LevelButtons.
 *
 * Used with the select menu.
 */
class LevelSelector : public Container
{
public:
	this(Container p, int x, int y, void delegate(Button b) dg)
	{
		auto levels = scanForLevels();
		char[] str;

		foreach(l; levels) {
			if (!l.beta)
				continue;

			auto lb = new LevelButton(this, l);
			lb.pressed ~= dg;
		}

		int pos;
		foreach(int i, c; getChildren()) {
			c.x = 0;
			c.y = pos;
			pos += c.h;
			w = imax(w, c.x + c.w);
			h = imax(h, c.y + c.h);
		}

		super(p, x, y, w, h);
	}
}

/**
 * A Button that displays the name of a level.
 *
 * Used with the select menu.
 */
class LevelButton : public Button
{
public:
	MinecraftLevelInfo info;

public:
	this(Container p, MinecraftLevelInfo info)
	{
		this.info = info;
		super(p, 0, 0, info.name, 32);
	}
}
