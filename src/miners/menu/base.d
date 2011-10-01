// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.menu.base;

import charge.charge;
import charge.game.gui.textbased;
import charge.game.gui.input;

import miners.menu.runner;


class MenuBase : public HeaderContainer
{
protected:
	MenuRunner mr;

	const bgColor = Color4f(0, 0, 0, 0.8);
	const fgColor = Color4f(0, 0, 1, 0.8);

public:
	this(MenuRunner mr, char[] header)
	{
		super(bgColor, header, fgColor);
		this.mr = mr;
	}
}
