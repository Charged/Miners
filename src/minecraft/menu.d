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
import minecraft.importer;

/**
 * Menu runner
 */
class MenuRunner : public Runner
{
protected:
	Router router;
	Runner levelRunner;

	GfxTextureTarget infoTexture;

	LevelButton currentButton;
	HeaderContainer hc;
	InputHandler ih;

	CtlKeyboard keyboard;
	CtlMouse mouse;
	bool inControl;

private:
	mixin SysLogging;

public:
	this(Router r)
	{
		this.router = r;

		makeInfoTexture();

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

		if (infoTexture !is null)
			infoTexture.dereference();
	}

	void resize(uint w, uint h)
	{
	}

	void logic()
	{
	}

	void render(GfxRenderTarget rt)
	{
		if (levelRunner !is null)
			levelRunner.render(rt);

		if (infoTexture is null)
			return;

		hc.x = (rt.width - infoTexture.width) / 2;
		hc.y = (rt.height - infoTexture.height) / 2;

		auto d = new GfxDraw();
		d.target = rt;
		d.start();
		d.blit(infoTexture, hc.x, hc.y);
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

protected:
	class CloseButton : public Button
	{
	protected:
		MinecraftLevelInfo info;

	public:
		this(Container p, int x, int y)
		{
			this.info = info;
			super(p, x, y, "Close", 8);
		}

		void mouseDown(CtlMouse, int x, int y, uint button)
		{
			if (levelRunner !is null)
				router.switchTo(levelRunner);
		}
	}

	class QuitButton : public Button
	{
	protected:
		MinecraftLevelInfo info;

	public:
		this(Container p, int x, int y)
		{
			this.info = info;
			super(p, x, y, "Quit", 8);
		}

		void mouseDown(CtlMouse, int x, int y, uint button)
		{
			if (levelRunner !is null) {
				router.deleteMe(levelRunner);
				levelRunner = null;
			}
			router.deleteMe(this.outer);
		}
	}

	class LevelButton : public Button
	{
	protected:
		MinecraftLevelInfo info;

	public:
		this(Container p, MinecraftLevelInfo info)
		{
			this.info = info;
			super(p, 0, 0, info.name, 32);
		}

		void mouseDown(CtlMouse, int x, int y, uint button)
		{
			if (currentButton is this)
				return;

			delete levelRunner;
			levelRunner = router.loadLevel(info.dir);
			currentButton = this;
		}
	}

	class LevelSelector : public Container
	{
	public:
		this(Container p, int x, int y)
		{
			auto levels = scanForLevels();
			char[] str;

			foreach(l; levels) {
				if (!l.beta)
					continue;

				new LevelButton(this, l);
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

private:
	void keyDown(CtlKeyboard kb, int sym)
	{
		if (sym != 27) // Escape
			return;

		if (levelRunner is null)
			return;

		if (inControl)
			router.switchTo(levelRunner);
		else
			router.switchTo(this);
	}

	void makeInfoTexture()
	{
		char[] str = selectText;
		hc = new HeaderContainer(Color4f(0, 0, 0, 0.8),
					 "Charged Miners",
					 Color4f(0, 0, 1, 0.8));
		auto it = new Text(hc, 0, 0, selectText);
		auto ls = new LevelSelector(hc, 0, it.h);
		auto cb = new CloseButton(hc, 0, it.h + ls.h + 16);
		auto qb = new QuitButton(hc, cb.w + 16, it.h + ls.h + 16);
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

		if (infoTexture !is null)
			infoTexture.dereference();
		infoTexture = hc.getTarget();
	}

	const char[] headerTextChars = `Charged Miners`;

	const char[] selectText =
`Welcome to charged miners, please select level below.

`;
}
