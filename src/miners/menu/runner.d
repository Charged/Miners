// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.menu.runner;

import std.math;
import std.string;

import charge.charge;
import charge.game.gui.textbased;
import charge.game.gui.input;

import miners.runner;
import miners.viewer;
import miners.importer.info;

/**
 * Menu runner
 */
class MenuRunner : public Runner
{
protected:
	Router router;
	Runner levelRunner;

	GfxTextureTarget menuTexture;

	Button currentButton;
	TextureContainer tc;
	InputHandler ih;

	CtlKeyboard keyboard;
	CtlMouse mouse;
	bool inControl;

	bool errorMode;

private:
	mixin SysLogging;

public:
	this(Router r, GameException ge = null)
	{
		this.router = r;

		ih = new InputHandler(null);

		keyboard = CtlInput().keyboard;
		mouse = CtlInput().mouse;

		keyboard.down ~= &this.keyDown;

		if (ge is null) {
			auto m = new MainMenu(this);
			changeWindow(m);
		} else {
			auto m = new ErrorMenu(this, ge.toString(), ge.next);
			changeWindow(m);
			errorMode = true;
		}
	}

	~this()
	{
		keyboard.down.disconnect(&this.keyDown);

		if (tc !is null)
			tc.breakApart();
		delete ih;
		delete levelRunner;

		if (menuTexture !is null)
			menuTexture.dereference();
	}

	void close()
	{
	}

	void resize(uint w, uint h)
	{
		if (levelRunner !is null)
			return levelRunner.resize(w, h);
	}

	void logic()
	{
		if (levelRunner !is null)
			return levelRunner.logic();
	}

	void render(GfxRenderTarget rt)
	{
		if (levelRunner !is null)
			levelRunner.render(rt);

		if (menuTexture is null)
			return;

		tc.x = (rt.width - menuTexture.width) / 2;
		tc.y = (rt.height - menuTexture.height) / 2;

		auto d = new GfxDraw();
		d.target = rt;
		d.start();

		if (levelRunner is null)
			d.fill(Color4f(0, 0, 0, 1), false, 0, 0, rt.width, rt.height);

		d.blit(menuTexture, tc.x, tc.y);
		d.stop();
	}

	bool build()
	{
		if (levelRunner !is null)
			return levelRunner.build();
		else
			return false;
	}

	void assumeControl()
	{
		ih.assumeControl();
		mouse.grab = false;
		mouse.show = true;
		inControl = true;
	}

	void dropControl()
	{
		ih.dropControl();
		inControl = false;
	}

	void manageThis(Runner r)
	{
		if (levelRunner !is null)
			router.deleteMe(levelRunner);

		levelRunner = r;

		if (levelRunner !is null)
			router.switchTo(levelRunner);
		else
			router.switchTo(this);
	}

package:
	/*
	 *
	 * Common callbacks.
	 *
	 */

	void commonMenuQuit(Button b)
	{
		if (levelRunner !is null) {
			router.deleteMe(levelRunner);
			levelRunner = null;
		}
		router.deleteMe(this);
	}

	void commonMenuClose(Button b)
	{
		if (levelRunner !is null) {
			router.switchTo(levelRunner);
			changeWindow(new MainMenu(this));
		}
	}


	/*
	 *
	 * Main menu callbacks and text.
	 *
	 */


	void mainMenuRandom(Button b)
	{
		selectMenuSelect(b);
	}

	void mainMenuClassic(Button b)
	{

	}

	void mainMenuSelectLevel(Button b)
	{
		changeWindow(new LevelMenu(this));
	}

	/*
	 *
	 * Select menu callbacks and text.
	 *
	 */

	void selectMenuSelect(Button b)
	{
		if (currentButton is b)
			return;

		if (levelRunner !is null)
			router.deleteMe(levelRunner);

		auto lb = cast(LevelButton)b;
		if (lb is null) {
			levelRunner = router.loadLevel(null);
		} else {
			levelRunner = router.loadLevel(lb.info.dir);
		}
		currentButton = b;
	}

	void selectMenuBack(Button b)
	{
		changeWindow(new MainMenu(this));
	}

private:
	void keyDown(CtlKeyboard kb, int sym)
	{
		if (sym != 27) // Escape
			return;

		if (errorMode)
			return router.deleteMe(this);

		if (levelRunner is null)
			return;

		if (inControl) {
			router.switchTo(levelRunner);
			changeWindow(new MainMenu(this));
		} else
			router.switchTo(this);
	}

	void changeWindow(TextureContainer c)
	{
		if (menuTexture !is null)
			menuTexture.dereference();
		if (tc !is null)
			tc.breakApart();
		this.tc = c;
		ih.setRoot(tc);
		tc.paint();
		menuTexture = tc.getTarget();
	}
}

class MainMenu : public HeaderContainer
{
private:
	Text te;
	Button ra;
	Button cl;
	Button be;
	Button cb;
	Button qb;

	const char[] header = `Charged Miners`;

	const char[] text =
`Welcome to charged miners, please select below.

`;

public:
	this(MenuRunner mr)
	{
		int pos;

		super(Color4f(0, 0, 0, 0.8), header, Color4f(0, 0, 1, 0.8));

		te = new Text(this, 0, 0, text);
		pos += te.h;
		ra = new Button(this, 0, pos, "Random", 32);
		pos += ra.h;
		cl = new Button(this, 0, pos, "Classic", 32);
		pos += cl.h;
		be = new Button(this, 0, pos, "Beta", 32);
		pos += be.h + 16;
		cb = new Button(this, 0, pos, "Close", 8);
		qb = new Button(this, 0, pos, "Quit", 8);

		ra.pressed ~= &mr.selectMenuSelect;
		cl.pressed ~= &mr.mainMenuClassic;
		be.pressed ~= &mr.mainMenuSelectLevel;
		cb.pressed ~= &mr.commonMenuClose;
		qb.pressed ~= &mr.commonMenuQuit;

		repack();

		auto center = plane.w / 2;

		// Center the children
		foreach(c; getChildren) {
			c.x = center - c.w/2;
		}

		// Place the buttons next to each other.
		cb.x = center + 8;
		qb.x = center - 8 - qb.w;
	}
}

class ErrorMenu : public HeaderContainer
{
private:
	Text te;
	Button qb;

	const char[] header = `Charged Miners`;

public:
	this(MenuRunner mr, char[] errorText, Exception e)
	{
		super(Color4f(0, 0, 0, 0.8), header, Color4f(0, 0, 1, 0.8));

		te = new Text(this, 0, 0, errorText);

		// And some extra info if we get a Exception.
		if (e !is null) {
			auto t = format(e.classinfo.name, " ", e);
			te = new Text(this, 0, te.h + 8, t);
		}

		// Add a quit button at the bottom.
		qb = new Button(this, 0, te.y + te.h + 8, "Quit", 8);
		qb.pressed ~= &mr.commonMenuQuit;

		repack();

		auto center = plane.w / 2;

		// Center the children
		foreach(c; getChildren) {
			c.x = center - c.w/2;
		}
	}
}

class LevelMenu : public HeaderContainer
{
private:
	Text te;
	LevelSelector ls;
	Button ba;

	const char[] header = `Select a level`;

	const char[] text =
`Welcome to charged miners, please select level below.

`;

public:
	this(MenuRunner mr)
	{
		super(Color4f(0, 0, 0, 0.8), header, Color4f(0, 0, 1, 0.8));

		te = new Text(this, 0, 0, text);
		ls = new LevelSelector(this, 0, te.h, &mr.selectMenuSelect);
		ba = new Button(this, 0, ls.y + ls.h + 16, "Back", 8);

		ba.pressed ~= &mr.selectMenuBack;

		repack();

		auto center = plane.w / 2;

		// Center the children
		foreach(c; getChildren) {
			c.x = center - c.w/2;
		}
	}
}

/**
 * A Button that displays the name of a level.
 *
 * Used with the select menu.
 */
class LevelButton : public Button
{
public:
	MinecraftLevelInfo info;

public:
	this(Container p, MinecraftLevelInfo info)
	{
		this.info = info;
		super(p, 0, 0, info.name, 32);
	}
}

/**
 * A Container for LevelButtons.
 *
 * Used with the select menu.
 */
class LevelSelector : public Container
{
public:
	this(Container p, int x, int y, void delegate(Button b) dg)
	{
		auto levels = scanForLevels();
		char[] str;

		foreach(l; levels) {
			if (!l.beta)
				continue;

			auto lb = new LevelButton(this, l);
			lb.pressed ~= dg;
		}

		int pos;
		foreach(int i, c; getChildren()) {
			c.x = 0;
			c.y = pos;
			pos += c.h;
			w = cast(int)fmax(w, c.x + c.w);
			h = cast(int)fmax(h, c.y + c.h);
		}

		super(p, x, y, w, h);
	}
}
