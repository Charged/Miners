// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.menu.pause;

import charge.charge;
import charge.game.gui.layout;
import charge.game.gui.textbased;

import miners.options;
import miners.interfaces;
import miners.menu.base;


class PauseMenu : public MenuBase
{
private:
	const char[] header = `Options`;
	const int minButtonWidth = 32;

	const aaOnText = "Aa: on";
	const aaOffText = "Aa: off";

	const fogOnText = "Fog: on";
	const fogOffText = "Fog: off";

	const shadowOnText = "Shadow: on";
	const shadowOffText = "Shadow: off";

	Options opts;

	const spacerStr = "                                               ";

public:
	this(Router r, Options opts)
	{
		super(r, header, Buttons.NONE);
		this.opts = opts;

		auto t = new Text(this, 0, 0, spacerStr);
		auto b1 = new Button(this, 0,               8, "", minButtonWidth);
		auto b2 = new Button(this, 0, b1.y + b1.h, "", minButtonWidth);
		auto b3 = new Button(this, 0, b2.y + b2.h, "", minButtonWidth);
		auto b4 = new Button(this, 0, b3.y + b3.h, "", minButtonWidth);

		int bY = b4.y + b4.h + 16;

		auto b5 = new Button(this, 0, bY, "Quit", 8);
		auto b6 = new Button(this, bY, bY, "Close", 8);

		setAaText(b1); b1.pressed ~= &aa;
		setFogText(b2); b2.pressed ~= &fog;
		setShadowText(b3); b3.pressed ~= &shadow;
		setViewText(b4); b4.pressed ~= &view;

		b5.pressed ~= &quit;
		b6.pressed ~= &close;

		repack();

		auto center = plane.w / 2;

		// Center the children
		foreach(c; getChildren) {
			c.x = center - c.w/2;
		}

		// Place the buttons next to each other.
		b5.x = center - 8 - b5.w;
		b6.x = center + 8;
	}

	void quit(Button b) { r.quit(); }
	void close(Button b) { r.menu.closeMenu(); }

	void view(Button b)
	{
		auto d = cast(int)opts.viewDistance() * 2;
		if (d > 2048)
			d = 32;
		opts.viewDistance = d;

		setViewText(b);
	}

	void setViewText(Button b)
	{
		char[] str;
		switch(cast(int)opts.viewDistance()) {
		case   32: str = "Distance: Tiny"; break;
		case   64: str = "Distance: Short"; break;
		case  128: str = "Distance: Medium"; break;
		case  256: str = "Distance: Far"; break;
		case  512: str = "Distance: Further"; break;
		case 1024: str = "Distance: Furthest"; break;
		case 2048: str = "Distance: Furthestest"; break;
		default:   str = "Distance: Unknown"; break;
		}
		b.setText(str, minButtonWidth);
	}

	void aa(Button b)
	{
		opts.aa.toggle();
		setAaText(b);
	}

	void setAaText(Button b)
	{
		b.setText(opts.aa() ? aaOnText : aaOffText, minButtonWidth);
	}

	void fog(Button b)
	{
		opts.fog.toggle();
		setFogText(b);
	}

	void setFogText(Button b)
	{
		b.setText(opts.fog() ? fogOnText : fogOffText, minButtonWidth);
	}

	void shadow(Button b)
	{
		opts.shadow.toggle();
		setShadowText(b);
	}

	void setShadowText(Button b)
	{
		b.setText(opts.shadow() ? shadowOnText : shadowOffText, minButtonWidth);
	}
}
