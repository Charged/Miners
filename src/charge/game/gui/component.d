// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for Component base class.
 */
module charge.game.gui.component;

import charge.ctl.mouse;
import charge.ctl.keyboard;
import charge.gfx.draw;
import charge.game.gui.input;
import charge.game.gui.container;

alias charge.ctl.mouse.Mouse Mouse;
alias charge.ctl.keyboard.Keyboard Keyboard;


abstract class Component
{
public:
	int x;
	int y;
	uint w;
	uint h;
	InputHandler input;

private:
	Container p;

public:
	this(Container p, int x, int y, uint w, uint h)
	{
		this.x = x;
		this.y = y;
		this.w = w;
		this.h = h;

		if (p !is null)
			p.add(this);
	}

	/**
	 * Get the parent of this component.
	 */
	Container parent() { return p; }

	/**
	 * Return the input handler for this component or any parent.
	 */
	final InputHandler getInput()
	{
		if (input !is null)
			return input;
		if (parent !is null)
			return parent.getInput();
		return null;
	}

	/**
	 * Repack this and any eventual children.
	 */
	abstract void repack();

	/**
	 * Paint this component using Draw.
	 */
	abstract void paint(Draw d);

	/**
	 * Disown any children and releases any resources.
	 */
	void breakApart()
	{
		releaseResources();
	}

	/**
	 * Releases any resources this component or any of its children has.
	 */
	abstract void releaseResources();

	/**
	 * Get the compenet at coordinate x, y, return absolute position.
	 */
	Component at(int x, int y, ref int absX, ref int absY)
	{
		if (x < 0 || y < 0 || x >= w || y >= h)
			return null;

		absX += this.x;
		absY += this.y;
		return this;
	}

	void getAbsolutePosition(ref int absX, ref int absY)
	{
		if (parent !is null)
			parent.getAbsolutePosition(absX, absY);

		absX += x;
		absY += y;
	}

	final bool isAncester(Component c)
	{
		if (parent is null)
			return false;
		if (parent is c)
			return true;
		return parent.isAncester(c);
	}

	final void repaint()
	{
		repaint(x, y, w, h);
	}

	void repaint(int x, int y, uint w, uint h)
	{
		if (parent is null)
			return;

		parent.repaint(this.x + x, this.y + y, w, h);
	}

	void mouseEnter(Mouse m, int x, int y) {}
	void mouseLeave(Mouse m, int x, int y) {}
	void mouseMove(Mouse m, int x, int y) {}
	void mouseDown(Mouse m, int x, int y, uint b) {}
	void mouseUp(Mouse m, int x, int y, uint b) {}

	void keyDown(Keyboard k, int sym, dchar unicode, char[] str) {}
	void keyUp(Keyboard k, int sym) {}

protected:
	this()
	{

	}

	~this()
	{

	}

	/**
	 * This component no longer is c's parent.
	 * Failes of c.parent is not this
	 */
	void disownChild(Component c)
	in {
		assert(c !is null);
		assert(c.parent is this);
	} body {
		c.p = null;
	}

	/**
	 * This component now becomes c's parent.
	 * Failes if c.parent is not null
	 */
	void becomeParent(Component c)
	in {
		assert(c !is null);
		assert(c !is this);
		assert(c.parent is null);
		assert(!isAncester(c));
		assert(cast(Container)this !is null);
	} body {
		c.p = cast(Container)this;
	}
}
