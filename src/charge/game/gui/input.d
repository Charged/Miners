// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.game.gui.input;

import charge.ctl.input;
import charge.game.gui.component;

class InputHandler
{
protected:
	Component root;
	Component keyboardFocus;

	bool inControl;
	Keyboard keyboard;
	Mouse mouse;

public:
	this()
	{
		this(null);
	}

	this(Component root)
	{
		this.root = root;
		keyboard = Input().keyboard;
		mouse = Input().mouse;
	}

	~this()
	{
		dropControl();
	}

	void setRoot(Component c)
	{
		focus(null);
		root = c;
	}

	void focus(Component c)
	{
		if (keyboardFocus !is null)
			keyboardFocus.notifyUnRegister(&unhook);
		keyboardFocus = c;
		if (keyboardFocus !is null)
			keyboardFocus.notifyRegister(&unhook);
	}

	void unfocus(Component c)
	{
		if (keyboardFocus is c)
			focus(null);
	}

	void assumeControl()
	{
		if (inControl)
			return;

		keyboard.up ~= &this.keyUp;
		keyboard.down ~= &this.keyDown;

		mouse.up ~= &this.mouseUp;
		mouse.down ~= &this.mouseDown;
		mouse.move ~= &this.mouseMove;

		inControl = true;
	}

	void dropControl()
	{
		if (!inControl)
			return;

		keyboard.up.disconnect(&this.keyUp);
		keyboard.down.disconnect(&this.keyDown);

		mouse.up.disconnect(&this.mouseUp);
		mouse.down.disconnect(&this.mouseDown);
		mouse.move.disconnect(&this.mouseMove);

		inControl = false;
	}

private:
	void unhook(Object obj)
	{
		assert(keyboardFocus is obj);
		keyboardFocus = null;
	}

	Component getComponent(int x, int y, out int tx, out int ty)
	{
		Component c;

		if (c is null)
			c = root.at(x - root.x, y - root.y, tx, ty);
		else
			c.getAbsolutePosition(tx, ty);

		tx = x - tx;
		ty = y - ty;

		return c;
	}

	void keyDown(Keyboard kb, int sym, dchar unicode, char[] str)
	{
		if (keyboardFocus is null)
			return;

		keyboardFocus.keyDown(kb, sym, unicode, str);
	}

	void keyUp(Keyboard kb, int sym)
	{
		if (keyboardFocus is null)
			return;

		keyboardFocus.keyUp(kb, sym);
	}

	void mouseMove(Mouse mouse, int ixrel, int iyrel)
	{
		if (root is null)
			return;

		int tx, ty;
		auto c = getComponent(mouse.x, mouse.y, tx, ty);

		if (c is null)
			return;

		c.mouseMove(mouse, tx, ty);
	}

	void mouseDown(Mouse m, int button)
	{
		if (root is null)
			return;

		int tx, ty;
		auto c = getComponent(mouse.x, mouse.y, tx, ty);

		if (c is null)
			return;

		c.mouseDown(mouse, tx, ty, button);
	}

	void mouseUp(Mouse m, int button)
	{
		if (root is null)
			return;

		int tx, ty;
		auto c = getComponent(mouse.x, mouse.y, tx, ty);

		if (c is null)
			return;

		c.mouseUp(mouse, tx, ty, button);
	}
}
