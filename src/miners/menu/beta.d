// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.menu.beta;

import charge.charge;
import charge.game.gui.layout;
import charge.game.gui.textbased;

import miners.interfaces;
import miners.runner;
import miners.menu.base;
import miners.importer.info;


class LevelMenu : public MenuBase
{
private:
	Text te;
	LevelSelector ls;

	const char[] header = `Select a level`;

	const char[] text =
`Welcome to charged miners, please select level below.`;

public:
	this(Router r)
	{
		super(r, header, Buttons.BACK);

		auto vc = new VerticalContainer(null, 0, 0, 0, 0, 16);
		replacePlane(vc);

		te = new Text(this, 0, 0, text);
		ls = new LevelSelector(this, 0, 0, &selectLevel);

		repack();
	}

	void selectLevel(Button b)
	{
		auto lb = cast(LevelButton)b;

		if (lb is null)
			r.loadLevel(null);
		else
			r.loadLevel(lb.info.dir);
	}
}

/**
 * A Container for LevelButtons.
 *
 * Used with the select menu.
 */
class LevelSelector : public VerticalContainer
{
public:
	this(Container p, int x, int y, void delegate(Button b) dg)
	{
		super(p, x, y, 0, 0, 0);

		auto levels = scanForLevels();
		char[] str;

		if (levels.length == 0)
			throw new GameException("No levels found", null);

		foreach(l; levels) {
			if (!l.beta)
				continue;

			auto lb = new LevelButton(this, l);
			lb.pressed ~= dg;
		}
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
