// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.classic.messagelog;

import charge.charge : sysReference, GfxDraw;
import charge.game.gui.container : Container;
import charge.game.gui.messagelog : MessageLog;
import miners.options : Options;


class ClassicMessageLog : MessageLog
{
public:
	Options opts;


public:
	this(Container c, Options opts, int x, int y, uint rows)
	{
		this.opts = opts;
		super(c, x, y, 64, rows, 0, 1);
	}

	override void makeResources()
	{
		sysReference(&bf, opts.classicFont());
	}


protected:
	override void drawRow(GfxDraw d, int y, string row)
	{
		bf.draw(d, 0, y, row);
	}
}
