// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for MenuRunner.
 */
module charge.game.menu;

static import charge.sys.logger;
static import charge.sys.resource;

import charge.core;
import charge.gfx.draw : Draw;
import charge.gfx.target : RenderTarget;
import charge.gfx.texture : TextureTarget;
import charge.ctl.input : Input;
import charge.ctl.mouse : Mouse;
import charge.ctl.keyboard : Keyboard;

import charge.game.runner : Runner, Router;
import charge.game.gui.container : TextureContainer;
import charge.game.gui.input : InputHandler;

alias charge.sys.logger.Logging SysLogging;
alias charge.sys.resource.reference reference;


/**
 * Base class for implementing menus.
 */
abstract class MenuRunner : Runner
{
protected:
	TextureTarget menuTexture;
	TextureContainer menu;
	Draw d;

	InputHandler ih;
	bool repaint;

	Keyboard keyboard;
	Mouse mouse;
	bool inControl;


private:
	mixin SysLogging;


public:
	this(TextureContainer menu)
	{
		super(Type.Menu);

		ih = new InputHandler(null);
		d = new Draw();

		keyboard = Input().keyboard;
		mouse = Input().mouse;

		setMenu(menu);
	}

	~this()
	{
		assert(menu is null);
		delete ih;

		reference(&menuTexture, null);
	}

	void close()
	{
		if (menu !is null) {
			menu.breakApart();
			menu = null;
		}

		reference(&menuTexture, null);
	}

	void setMenu(TextureContainer newMenu)
	{
		reference(&menuTexture, null);
		if (menu !is null)
			menu.breakApart();

		menu = newMenu;
		ih.setRoot(menu);

		if (menu is null)
			return;

		menu.repaintDg = &triggerRepaint;
	}

	void resize(uint w, uint h)
	{
	}

	void logic()
	{
	}

	void render(RenderTarget rt)
	{
		if (menu is null)
			return;

		if (repaint || menuTexture is null) {
			menu.paintTexture();

			reference(&menuTexture, menu.texture);
			repaint = false;
		}

		if (menuTexture is null)
			return;

		menu.x = (rt.width - menuTexture.width) / 2;
		menu.y = (rt.height - menuTexture.height) / 2;

		d.target = rt;
		d.start();

		d.blit(menuTexture, menu.x, menu.y);
		d.stop();
	}

	void assumeControl()
	{
		uint w, h;
		bool fullscreen;
		Core().size(w, h, fullscreen);

		keyboard.down ~= &this.keyDown;
		ih.assumeControl();

		auto shouldReset = !mouse.show();
		mouse.grab = false;
		mouse.show = true;
		if (shouldReset)
			mouse.warp(w / 2, h / 2);
		inControl = true;
	}

	void dropControl()
	{
		keyboard.down -= &this.keyDown;
		ih.dropControl();
		inControl = false;
	}


protected:
	abstract void escapePressed();

	void keyDown(Keyboard kb, int sym, dchar unicode, char[] str)
	{
		if (sym != 27) // Escape
			return;

		escapePressed();
	}

	void triggerRepaint()
	{
		repaint = true;
	}
}
