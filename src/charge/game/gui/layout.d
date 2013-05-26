// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for layout components.
 */
module charge.game.gui.layout;

import charge.math.ints;
import charge.game.gui.container;


class VerticalContainer : Container
{
public:
	uint minWidth;
	uint minHeight;
	uint spacing;

public:
	this(Container p, int x, int y,
	     uint minWidth, uint minHeight,
	     uint spacing)
	{
		super(p, x, y, minWidth, minHeight);
		this.minWidth = minWidth;
		this.minHeight = minHeight;
		this.spacing = spacing;
	}

	override void repack()
	{
		w = minWidth;
		h = minHeight;

		int pos;
		foreach(int i, c; getChildren()) {
			c.repack();
			c.y = pos;
			pos += c.h + spacing;

			w = imax(w, c.x + c.w);
			h = imax(h, c.y + c.h);
		}

		// Center the children
		auto center = w / 2;
		foreach(c; getChildren) {
			c.x = center - c.w/2;
		}
	}
}
