// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for Container class.
 */
module charge.game.gui.container;

import charge.math.ints;
import charge.math.color;
import charge.util.vector;
import charge.gfx.draw;
import charge.gfx.texture;
import charge.sys.resource : reference;
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

class Container : Component
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

/**
 * Base class for containers that render into a texture.
 */
abstract class TextureTargetContainer : Container
{
public:
	void delegate() repaintDg;
	Color4f bg;

protected:
	TextureTarget tt;

public:
	this(Container c, int x, int y, uint w, uint h,
	     Color4f bg = Color4f(0, 0, 0, 0))
	{
		super(c, x, y, w, h);
		this.bg = bg;
	}

	~this()
	{
		assert(tt is null);
	}

	void releaseResources()
	{
		super.releaseResources();

		reference(&tt, null);
	}

	void repaint(int x, int y, uint w, uint h)
	{
		super.repaint(x, y, w, h);

		if (repaintDg is null)
			return;

		repaintDg();
	}

	void paintBackground(Draw d)
	{
		d.fill(bg, false, 0, 0, w, h);
	}

	/**
	 * Paint this container to the current texture target.
	 *
	 * Create a new one if size differs or if none is attached.
	 */
	void paintTexture()
	{
		if (tt is null || (tt.width != w || tt.height != h)) {
			reference(&tt, null);
			tt = TextureTarget(w, h);
		}

		auto d = new Draw();
		d.target = tt;
		d.start();

		super.paint(d);

		d.stop();

		delete d;
	}

	void paint(Draw d)
	{
		// Not the intended use.
		assert(false);
	}
}

/**
 * Class intended to be the bottom of a rendering stack.
 */
class TextureContainer : TextureTargetContainer
{
public:
	this(uint w, uint h)
	{
		super(null, 0, 0, w, h);
	}

	this(uint w, uint h, Color4f bg)
	{
		super(null, 0, 0, w, h, bg);
	}

	/**
	 * Return the current texture target, receiver must reference.
	 */
	Texture texture()
	{
		return tt;
	}
}

/**
 * Caches the rendering result in a texture thereby
 * stopping paint to decend to children.
 */
class CacheContainer : TextureTargetContainer
{
public:
	this(Container c, int x, int y, uint w, uint h)
	{
		super(c, x, y, w, h);
	}

	this(Container c, int x, int y, uint w, uint h, Color4f bg)
	{
		super(c, x, y, w, h, bg);
	}

	void paint(Draw d)
	{
		d.blit(tt, Color4f.White, true,
		       0, 0, w, h,  // srcX, srcY, srcW, srcH
		       0, 0, w, h); // dstX, dstY, dstW, dstH
	}
}

/**
 * Does the same as ChacheContainer only drawing it anti-aliased.
 */
class AntiAliasingContainer : TextureTargetContainer
{
public:
	this(Container c, int x, int y, uint w, uint h)
	{
		super(c, x, y, w, h);
	}

	this(Container c, int x, int y, uint w, uint h, Color4f bg)
	{
		super(c, x, y, w, h, bg);
	}

	/**
	 * Paint this container to the current texture target while
	 * also appling a anti-aliasing effect.
	 *
	 * Create a new one if size differs or if none is attached.
	 */
	void paintTexture()
	{
		auto dW = w * 2;
		auto dH = h * 2;

		if (tt is null || (tt.width != dW || tt.height != dH)) {
			reference(&tt, null);
			tt = TextureTarget(dW, dH);
			tt.filter = Texture.Filter.LinearNone;
		}

		auto d = new Draw();
		d.target = tt;
		d.start();

		d.scale(2, 2);

		Container.paint(d);

		d.stop();

		delete d;
	}

	void paint(Draw d)
	{
		d.blit(tt, Color4f.White, true,
		       0, 0, w*2, h*2,  // srcX, srcY, srcW, srcH
		       0, 0, w,   h  ); // dstX, dstY, dstW, dstH
	}
}
