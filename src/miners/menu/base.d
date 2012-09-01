// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.menu.base;

import charge.charge;
import charge.game.gui.textbased;

import miners.options;
import miners.interfaces;


class MenuRunnerBase : public GameMenuRunner
{
public:
	Router r;
	Options opts;


public:
	this(Router r, Options opts, TextureContainer menu)
	{
		this.r = r;
		this.opts = opts;
		super(menu);
	}

	void escapePressed()
	{
		// Close this runner
		r.deleteMe(this);
	}
}


class MenuBase : public HeaderContainer
{
public:
	Button button;

	const bgColor = Color4f(0, 0, 0, 0.8);
	const fgColor = Color4f(Color4b(0xb8_02_c3_ff));

	enum Buttons {
		NONE,
		OK,
		QUIT,
		BACK,
		CANCEL
	}

	const string[] buttonStrings = [
		"N/A",
		"Ok",
		"Quit",
		"Back",
		"Cancel",
	];


public:
	this(string header)
	{
		super(bgColor, header, fgColor);
	}

	this(string header, Buttons buttons)
	{
		this(header);

		// No need to add a button.
		if (buttons == Buttons.NONE)
			return;

		auto t = buttonStrings[buttons];
		button = new Button(null, 0, 0, t, 8);

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
