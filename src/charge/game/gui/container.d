// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.game.gui.container;

import charge.math.ints;
import charge.util.vector;
import charge.gfx.draw;
import charge.gfx.texture;
import charge.game.gui.component;


bool collidesWith(Component c, int x, int y, uint w, uint h)
{
	int xw = x + w;
	int yw = y + h;

	int x2 = c.x;
	int y2 = c.y;
	int xw2 = x2 + c.w;
	int yw2 = y2 + c.h;

	if (x < xw2 && x2 < xw)
		if (y < yw2 && y2 < yw)
			return true;

	return false;
}

class Container : public Component
{
protected:
	Vector!(Component) children;

public:
	this(Container c, int x, int y, uint w, uint h)
	{
		super(c, x, y, w, h);
	}

	void repack()
	{
		w = 0;
		h = 0;

		foreach(c; children) {
			c.repack();
			w = imax(c.x + c.w, w);
			h = imax(c.y + c.h, h);
		}
	}

	Component[] getChildren()
	{
		return children.adup;
	}

	Component at(int x, int y, inout int absX, inout int absY)
	{
		absX += this.x;
		absY += this.y;

		foreach_reverse(c; children) {
			if (!collidesWith(c, x, y, 1, 1))
				continue;

			return c.at(x - c.x, y - c.y, absX, absY);
		}

		if (x < 0 || y < 0 || x >= w || y >= h)
			return null;

		return this;
	}

	/**
	 * Remove this component from this container.
	 */
	bool remove(Component c)
	{
		if (c is null)
			return false;

		if (c.parent !is this) {
			return false;
		}

		auto n = find(c);

		// If we are its parent then it should be among the children.
		assert(n >= 0);
		if (n < 0)
			return false;

		children.remove(c);

		disownChild(c);
		return true;
	}

	/**
	 * Add a unparented component as a child of this component.
	 */
	bool add(Component c)
	{
		if (c is null || c.parent !is null)
			return false;

		children ~= c;

		becomeParent(c);
		return true;
	}

	/**
	 * Find the location of this component in the list of children.
	 */
	int find(Component c)
	{
		foreach(int i, child; children[])
			if (child is c)
				return i;

		return -1;
	}

	void paint(Draw d)
	{
		paintBackground(d);
		paintComponents(d);
		paintForeground(d);
	}

	void breakApart()
	{
		while(children.length > 0) {
			auto i = children.length-1;
			auto c = children[i];

			c.breakApart();
			children.remove(i);
			disownChild(c);
		}

		releaseResources();
	}

	void releaseResources()
	{
		foreach(c; children)
			c.releaseResources();
	}

protected:
	void paintBackground(Draw d)
	{

	}

	void paintComponents(Draw d)
	{
		foreach(c; children) {
			d.save();
			d.translate(c.x, c.y);
			c.paint(d);
			d.restore();
		}
	}

	void paintForeground(Draw d)
	{

	}
}

class TextureContainer : public Container
{
public:
	TextureTarget tt;
	void delegate() repaintDg;

public:
	this(Container c, int x, int y, uint w, uint h)
	{
		super(c, x, y, w, h);
	}

	~this()
	{
		assert(tt is null);
	}

	void repaint(int x, int y, uint w, uint h)
	{
		if (repaintDg is null)
			return;

		repaintDg();
	}

	/**
	 * Return the current texture target, referenced.
	 */
	Texture texture()
	{
		return tt;
	}

	/**
	 * Paint this container to the current texture target.
	 *
	 * Create a new one if size differs or if none is attached.
	 */
	void paint()
	{
		if (tt is null || (tt.width != w || tt.height != h)) {
			tt.reference(&tt, null);
			tt = TextureTarget(null, w, h);
		}

		auto d = new Draw();
		d.target = tt;
		d.start();

		super.paint(d);

		d.stop();

		delete d;
	}

	void releaseResources()
	{
		super.releaseResources();

		tt.reference(&tt, null);
	}
}
