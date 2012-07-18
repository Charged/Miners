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
import miners.menu.pause;
import miners.menu.classic;
import miners.menu.blockselector;


/**
 * Menu runner
 */
class MenuRunner : public Runner, public MenuManager
{
public:
	bool active;
	Router r;
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
		super(Type.Menu);

		this.r = r;
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
		assert(ih is null);
		assert(menu is null);
		assert(menuTexture is null);
	}

	void close()
	{
		if (menu !is null) {
			menu.breakApart();
			menu = null;
		}

		sysReference(&menuTexture, null);

		delete ih;
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
		closeMenu();
		r.push(new MainMenu(r, opts));
	}

	void displayPauseMenu()
	{
		r.push(new PauseMenu(r, opts));
	}

	void displayLevelSelector()
	{
		try {
			auto lm = new LevelMenu(r, opts);
			r.push(lm);
		} catch (Exception e) {
			displayError(e, false);
		}
	}

	void displayClassicBlockSelector(void delegate(ubyte) selectedDg)
	{
		r.push(new ClassicBlockMenu(r, opts, selectedDg));
	}

	void displayClassicMenu()
	{
		auto psc = opts.playSessionCookie();

		r.push(new WebpageInfoMenu(r, opts, psc));
	}

	void displayClassicList(ClassicServerInfo[] csis)
	{
		r.push(new ClassicServerListMenu(r, opts, csis));
	}

	void getClassicServerInfoAndConnect(ClassicServerInfo csi)
	{
		auto psc = opts.playSessionCookie();

		r.push(new WebpageInfoMenu(r, opts, psc, csi));
	}

	void connectToClassic(char[] usr, char[] pwd, ClassicServerInfo csi)
	{
		r.push(new WebpageInfoMenu(r, opts, usr, pwd, csi));
	}

	void connectToClassic(ClassicServerInfo csi)
	{
		r.push(new ClassicConnectingMenu(r, opts, csi));
	}

	void classicWorldChange(ClassicConnection cc)
	{
		r.push(new ClassicConnectingMenu(r, opts, cc));
	}

	void displayInfo(char[] header, char[][] texts,
	                 char[] buttonText, void delegate() dg)
	{
		r.push(new InfoMenu(r, opts, header, texts, buttonText, dg));
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
		r.push(new ErrorMenu(r, texts, panic));
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
			return r.quit();

		if (inControl)
			closeMenu();
	}

	void changeWindow(MenuBase mb)
	{
		// XXX this code is going to be killed
		assert(mb is null);

		sysReference(&menuTexture, null);
		if (menu !is null)
			menu.breakApart();
		menu = mb;
		ih.setRoot(menu);

		if (menu is null) {
			active = false;
			r.backgroundMenu();
			return;
		}

		if (!active) {
			active = true;
			r.foregroundMenu();
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
