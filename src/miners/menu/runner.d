// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.menu.runner;

import charge.charge;
import charge.game.gui.input;
import charge.game.gui.textbased;

import miners.types;
import miners.error;
import miners.runner;
import miners.viewer;
import miners.options;
import miners.interfaces;
import miners.menu.base;
import miners.menu.main;
import miners.menu.beta;
import miners.menu.list;
import miners.menu.error;
import miners.menu.classic;
import miners.menu.blockselector;


/**
 * Menu runner
 */
class MenuRunner : public Runner, public MenuManager
{
public:
	bool active;
	Router router;
	Options opts;

protected:
	GfxTextureTarget menuTexture;
	GfxDraw d;

	MenuBase menu;
	InputHandler ih;
	bool repaint;

	CtlKeyboard keyboard;
	CtlMouse mouse;
	bool inControl;

	bool errorMode;

public:
	void delegate() ticker;

private:
	mixin SysLogging;

public:
	this(Router r, Options opts)
	{
		this.router = r;
		this.opts = opts;

		ih = new InputHandler(null);

		keyboard = CtlInput().keyboard;
		mouse = CtlInput().mouse;

		d = new GfxDraw();

		//auto m = new MainMenu(this.router);
		changeWindow(null);
	}

	~this()
	{
		if (menu !is null)
			menu.breakApart();
		delete ih;

		sysReference(&menuTexture, null);
	}

	void close()
	{
		if (menu !is null) {
			menu.breakApart();
			menu = null;
		}

		sysReference(&menuTexture, null);
	}

	void resize(uint w, uint h)
	{
	}

	void logic()
	{
		if (ticker !is null)
			ticker();
	}

	void render(GfxRenderTarget rt)
	{
		if (menuTexture is null)
			return;

		if (repaint) {
			menu.paintTexture();

			sysReference(&menuTexture, menu.texture);
			repaint = false;
		}

		menu.x = (rt.width - menuTexture.width) / 2;
		menu.y = (rt.height - menuTexture.height) / 2;

		d.target = rt;
		d.start();

		d.blit(menuTexture, menu.x, menu.y);
		d.stop();
	}

	bool build()
	{
		return false;
	}

	void assumeControl()
	{
		uint w, h;
		bool fullscreen;
		Core().size(w, h, fullscreen);

		keyboard.down ~= &this.keyDown;
		ih.assumeControl();
		mouse.grab = false;
		mouse.show = true;
		mouse.warp(w / 2, h / 2);
		inControl = true;
	}

	void dropControl()
	{
		keyboard.down -= &this.keyDown;
		ih.dropControl();
		inControl = false;
	}


	/*
	 *
	 * MenuManager functions.
	 *
	 */


	void closeMenu()
	{
		changeWindow(null);
	}

	void displayMainMenu()
	{
		changeWindow(new MainMenu(this.router));
	}

	void displayLevelSelector()
	{
		try {
			auto lm = new LevelMenu(this.router);
			changeWindow(lm);
		} catch (Exception e) {
			displayError(e, false);
		}
	}

	void displayClassicBlockSelector(void delegate(ubyte) selectedDg)
	{
		changeWindow(new ClassicBlockMenu(this.router, opts, selectedDg));
	}

	void displayClassicMenu()
	{
		auto r = this.router;
		auto psc = opts.playSessionCookie();

		changeWindow(new ClassicServerListMenu(r, psc));
	}

	void connectToClassic(char[] usr, char[] pwd, ClassicServerInfo csi)
	{
		changeWindow(new WebpageInfoMenu(this.router, usr, pwd, csi));
	}

	void connectToClassic(ClassicServerInfo csi)
	{
		changeWindow(new ClassicConnectingMenu(this.router, csi));
	}

	void classicWorldChange(ClassicConnection cc)
	{
		changeWindow(new ClassicConnectingMenu(this.router, cc));
	}

	void displayError(Exception e, bool panic)
	{
		// Always handle exception via the game exception.
		auto ge = cast(GameException)e;
		if (ge is null)
			ge = new GameException(null, e, panic);


		char[][] texts;
		auto next = ge.next;

		if (next is null) {
			texts = [ge.toString()];
		} else {
			texts = [
				ge.toString(),
				next.classinfo.name,
				next.toString()
			];
		}

		displayError(texts, ge.panic);
	}

	void displayError(char[][] texts, bool panic)
	{
		auto m = new ErrorMenu(this.router, texts, panic);
		changeWindow(m);
		errorMode = panic;
	}

	void setTicker(void delegate() dg)
	{
		ticker = dg;
	}

	void unsetTicker(void delegate() dg)
	{
		if (ticker is dg)
			ticker = null;
	}

private:
	void keyDown(CtlKeyboard kb, int sym, dchar unicode, char[] str)
	{
		if (sym != 27) // Escape
			return;

		if (errorMode)
			return router.quit();

		if (inControl)
			closeMenu();
	}

	void changeWindow(MenuBase mb)
	{
		sysReference(&menuTexture, null);
		if (menu !is null)
			menu.breakApart();
		menu = mb;
		ih.setRoot(menu);

		if (menu is null) {
			active = false;
			router.foregroundCurrent();
			return;
		}

		if (!active) {
			active = true;
			router.backgroundCurrent();
		}

		menu.paintTexture();
		menu.repaintDg = &triggerRepaint;
		sysReference(&menuTexture, menu.texture);
	}

	void triggerRepaint()
	{
		repaint = true;
	}
}
