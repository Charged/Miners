// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.menu.base;

import charge.charge;
import charge.game.gui.textbased;

import miners.interfaces;


class MenuBase : public HeaderContainer
{
protected:
	Router r;
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
	this(Router r, char[] header)
	{
		super(bgColor, header, fgColor);
		this.r = r;
	}

	this(Router r, char[] header, Buttons buttons)
	{
		this(r, header);

		// No need to add a button.
		if (buttons == Buttons.NONE)
			return;

		auto t = buttonStrings[buttons];
		button = new Button(null, 0, 0, t, 8);

		switch (buttons) {
		case Buttons.OK:
		case Buttons.BACK:
		case Buttons.CANCEL:
			button.pressed ~= &back;
			break;
		case Buttons.QUIT:
			button.pressed ~= &quit;
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

private:
	void quit(Button b) { r.quit(); }

	void back(Button b) { r.menu.displayMainMenu(); }
}
