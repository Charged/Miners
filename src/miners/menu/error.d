// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.menu.error;

import std.string;

import charge.charge;
import charge.game.gui.layout;
import charge.game.gui.textbased;

import miners.interfaces;
import miners.menu.base;


class InfoMenu : public MenuBase
{
private:
	Button b;
	Text te[];
	void delegate() dg;

public:
	this(Router r, char[] header, char[][] texts, char[] buttonText, void delegate() dg)
	{
		super(r, header, Buttons.NONE);
		this.dg = dg;

		auto vc = new VerticalContainer(this, 0, 0, 300, 0, 8);
		foreach(uint i, t; texts)
			new Text(vc, 0, 0, t);
		vc.repack();

		b = new Button(this, 0, 0, buttonText, 8);
		b.pressed ~= &pressed;
		b.x = (vc.w - b.w) / 2;
		b.y = vc.y + vc.h + 16;

		repack();
	}

	void pressed(Button b)
	{
		if (dg !is null)
			dg();
		else
			r.menu.closeMenu();
	}
}


class ErrorMenu : public MenuBase
{
private:
	Text te[];

	const char[] header = `Charged Miners`;

public:
	this(Router r, char[][] errorTexts, bool panic)
	{
		auto b = panic ? Buttons.QUIT : Buttons.OK;
		super(r, header, b);

		auto vc = new VerticalContainer(null, 0, 0, 300, 0, 8);
		replacePlane(vc);

		te.length = errorTexts.length;
		foreach(uint i, t; errorTexts) {
			te[i] = new Text(this, 0, 0, t);
		}

		repack();
	}
}
