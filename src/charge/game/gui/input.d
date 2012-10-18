// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for InputHandler helper.
 */
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
		keyboard = Input().keyboard;
		mouse = Input().mouse;
		this.setRoot(root);
	}

	~this()
	{
		dropControl();
		if (root !is null)
			root.notifyUnRegister(&unhookRoot);
		if (keyboardFocus !is null)
			keyboardFocus.notifyRegister(&unhookFocus);
	}

	void setRoot(Component c)
	{
		if (root !is null) {
			root.notifyUnRegister(&unhookRoot);
			root.input = null;
		}
		focus(null);
		root = c;
		if (root !is null) {
			root.notifyRegister(&unhookRoot);
			root.input = this;
		}
	}

	void focus(Component c)
	{
		if (keyboardFocus !is null)
			keyboardFocus.notifyUnRegister(&unhookFocus);
		keyboardFocus = c;
		if (keyboardFocus !is null)
			keyboardFocus.notifyRegister(&unhookFocus);
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
	void unhookRoot(Object obj)
	{
		assert(root is obj);
		root = null;
	}

	void unhookFocus(Object obj)
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
