// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.menu.base;

import charge.charge;
import charge.game.gui.textbased;

import miners.menu.runner;


class MenuBase : public HeaderContainer
{
protected:
	MenuRunner mr;
	Button button;

	const bgColor = Color4f(0, 0, 0, 0.8);
	const fgColor = Color4f(0, 0, 1, 0.8);

	enum Buttons {
		NONE,
		OK,
		QUIT,
		BACK,
		CANCEL
	}
	const char[][] buttonStrings = [
		"N/A",
		"Ok",
		"Quit",
		"Back",
		"Cancel",
	];

public:
	this(MenuRunner mr, char[] header)
	{
		super(bgColor, header, fgColor);
		this.mr = mr;
	}

	this(MenuRunner mr, char[] header, Buttons buttons)
	{
		this(mr, header);

		// No need to add a button.
		if (buttons == Buttons.NONE)
			return;

		auto t = buttonStrings[buttons];
		button = new Button(null, 0, 0, t, 8);

		switch (buttons) {
		case Buttons.OK:
		case Buttons.BACK:
		case Buttons.CANCEL:
			button.pressed ~= &mr.commonMenuBack;
			break;
		case Buttons.QUIT:
			button.pressed ~= &mr.commonMenuQuit;
			break;
		default:
			assert(false);
		}

		Container.add(button);
	}

	void repack()
	{
		super.repack();

		if (button is null)
			return;

		button.x = w/2 - button.w/2;

		button.y = h;
		h += button.h + 8;
	}
}
