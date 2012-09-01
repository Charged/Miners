// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.menu.error;

import std.string;

import charge.charge;
import charge.game.gui.layout;
import charge.game.gui.textbased;

import miners.options;
import miners.interfaces;
import miners.menu.base;


class InfoMenu : public MenuRunnerBase
{
private:
	Router r;
	Button b;
	Text te[];
	void delegate() dg;

public:
	this(Router r, Options opts,
	     string header, string[] texts,
	     string buttonText, void delegate() dg)
	{
		this.r = r;
		this.dg = dg;

		auto mb = new MenuBase(header);
		auto vc = new VerticalContainer(mb, 0, 0, 300, 0, 8);
		foreach(uint i, t; texts)
			new Text(vc, 0, 0, t);
		vc.repack();

		b = new Button(mb, 0, 0, buttonText, 8);
		b.pressed ~= &pressed;
		b.x = (vc.w - b.w) / 2;
		b.y = vc.y + vc.h + 16;

		mb.repack();

		super(r, opts, mb);
	}

	void pressed(Button b)
	{
		if (dg !is null)
			dg();
		r.deleteMe(this);
	}
}


class ErrorMenu : public InfoMenu
{
private:
	const string header = `Charged Miners`;
	bool panic;

public:
	this(Router r, string[] errorTexts, bool panic)
	{
		this.panic = panic;
		auto txt = panic ? "Quit" : "Ok";
		auto dg = panic ? &r.quit : &r.displayMainMenu;

		super(r, opts, header, errorTexts, txt, dg);
	}

	void escapePressed()
	{
		if (panic)
			r.quit();
		else
			super.escapePressed();
	}
}
