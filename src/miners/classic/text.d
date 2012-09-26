// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.classic.text;

import charge.charge : sysReference;
import charge.game.gui.component : Container;
import charge.game.gui.text;
import miners.options : Options;


class ClassicText : Text
{
public:
	Options opts;


public:
	this(Container c, Options opts, int x, int y, string text)
	{
		this.opts = opts;
		super(c, x, y, text, true);
	}

	void makeResources()
	{
		sysReference(&bf, opts.classicFont());
	}
}
