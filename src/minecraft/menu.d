// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.menu;

import std.math;
import std.string;

import charge.charge;
import charge.game.gui.textbased;
import charge.game.gui.input;

import minecraft.runner;
import minecraft.viewer;
import minecraft.importer.info;

/**
 * Menu runner
 */
class MenuRunner : public Runner
{
protected:
	Router router;
	Runner levelRunner;

	GfxTextureTarget menuTexture;

	LevelButton currentButton;
	HeaderContainer hc;
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

		if (ge is null) {
			makeLevelSelector();
		} else {
			makeErrorText(ge.toString(), ge.next);
			errorMode = true;
		}

		keyboard = CtlInput().keyboard;
		mouse = CtlInput().mouse;

		ih = new InputHandler(hc);

		keyboard.down ~= &this.keyDown;
	}

	~this()
	{
		keyboard.down.disconnect(&this.keyDown);

		delete ih;
		delete hc;
		delete levelRunner;

		if (menuTexture !is null)
			menuTexture.dereference();
	}

	void resize(uint w, uint h)
	{
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

		hc.x = (rt.width - menuTexture.width) / 2;
		hc.y = (rt.height - menuTexture.height) / 2;

		auto d = new GfxDraw();
		d.target = rt;
		d.start();

		if (levelRunner is null)
			d.fill(Color4f(0, 0, 0, 1), false, 0, 0, rt.width, rt.height);

		d.blit(menuTexture, hc.x, hc.y);
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

private:
	void keyDown(CtlKeyboard kb, int sym)
	{
		if (sym != 27) // Escape
			return;

		if (errorMode)
			return router.deleteMe(this);

		if (levelRunner is null)
			return;

		if (inControl)
			router.switchTo(levelRunner);
		else
			router.switchTo(this);
	}

	void makeErrorText(char[] errorText, Exception e)
	{
		if (menuTexture !is null)
			menuTexture.dereference();

		assert(hc is null);
		hc = new HeaderContainer(Color4f(0, 0, 0, 0.8),
					 "Charged Miners",
					 Color4f(0, 0, 1, 0.8));

		auto text = new Text(hc, 0, 0, errorText);

		// And some extra info if we get a Exception.
		if (e !is null) {
			auto t = format(e.classinfo.name, " ", e);
			text = new Text(hc, 0, text.h + 8, t);
		}

		// Add a quit button at the bottom.
		auto qb = new Button(hc, 0, text.y + text.h + 8, "Quit", 8);
		qb.pressed ~= &menuQuit;

		hc.repack();
		auto center = hc.plane.w / 2;

		// Center the children
		foreach(c; hc.getChildren) {
			c.x = center - c.w/2;
		}

		// Paint the texture.
		hc.paint();

		menuTexture = hc.getTarget();
	}

	void makeLevelSelector()
	{
		if (menuTexture !is null)
			menuTexture.dereference();

		assert(hc is null);
		hc = new HeaderContainer(Color4f(0, 0, 0, 0.8),
					 "Charged Miners",
					 Color4f(0, 0, 1, 0.8));
		auto it = new Text(hc, 0, 0, selectText);
		auto ls = new LevelSelector(hc, 0, it.h, &selectMenuSelect);
		auto cb = new Button(hc, 0, it.h + ls.h + 16, "Close", 8);
		auto qb = new Button(hc, cb.w + 16, it.h + ls.h + 16, "Quit", 8);
		cb.pressed ~= &selectMenuClose;
		qb.pressed ~= &menuQuit;
		hc.repack();

		auto center = hc.plane.w / 2;

		// Center the children
		foreach(c; hc.getChildren) {
			c.x = center - c.w/2;
		}

		// Place the buttons next to each other.
		cb.x = center + 8;
		qb.x = center - 8 - qb.w;

		// Paint the texture.
		hc.paint();

		menuTexture = hc.getTarget();
	}


	/*
	 *
	 * Common callbacks.
	 *
	 */

	void menuQuit(Button b)
	{
		if (levelRunner !is null) {
			router.deleteMe(levelRunner);
			levelRunner = null;
		}
		router.deleteMe(this);
	}


	/*
	 *
	 * Select menu callbacks and text.
	 *
	 */

	void selectMenuClose(Button b)
	{
		if (levelRunner !is null)
			router.switchTo(levelRunner);
	}

	void selectMenuSelect(Button b)
	{
		auto lb = cast(LevelButton)b;
		if (currentButton is lb)
			return;

		delete levelRunner;
		levelRunner = router.loadLevel(lb.info.dir);
		currentButton = lb;
	}

	const char[] headerTextChars = `Charged Miners`;

	const char[] selectText =
`Welcome to charged miners, please select level below.

`;
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
		foreach(c; getChildren()) {
			c.x = 0;
			c.y = pos;
			pos += c.h;
			w = cast(int)fmax(w, c.x + c.w);
			h = cast(int)fmax(h, c.y + c.h);
		}

		super(p, x, y, w, h);
	}
}
