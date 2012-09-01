// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.menu.beta;

import charge.charge;
import charge.game.gui.layout;
import charge.game.gui.textbased;

import miners.error;
import miners.options;
import miners.interfaces;
import miners.menu.base;
import miners.importer.info;


class LevelMenu : MenuRunnerBase
{
private:
	const string header = `Select a level`;

	const string text =
`Welcome to charged miners, please select level below.`;

public:
	this(Router r, Options opts)
	{
		auto mb = new MenuBase(header, MenuBase.Buttons.BACK);
		mb.button.pressed ~= &back;

		auto vc = new VerticalContainer(null, 0, 0, 0, 0, 16);
		mb.replacePlane(vc);

		auto te = new Text(mb, 0, 0, text);
		auto ls = new LevelSelector(mb, 0, 0, &selectLevel);

		mb.repack();

		super(r, opts, mb);
	}

	void selectLevel(Button b)
	{
		auto lb = cast(LevelButton)b;

		if (lb is null)
			r.loadLevelModern(null);
		else
			r.loadLevelModern(lb.info.dir);
	}

	void back(Button b)
	{
		r.displayMainMenu();
		r.deleteMe(this);
	}
}

/**
 * A Container for LevelButtons.
 *
 * Used with the select menu.
 */
class LevelSelector : VerticalContainer
{
public:
	this(Container p, int x, int y, void delegate(Button b) dg)
	{
		super(p, x, y, 0, 0, 0);

		auto levels = scanForLevels();
		string str;

		if (levels.length == 0)
			throw new GameException("No levels found", null, false);

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
class LevelButton : Button
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
