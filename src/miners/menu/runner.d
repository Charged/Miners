// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.menu.runner;

import charge.charge;
import charge.game.gui.input;
import charge.game.gui.textbased;

import miners.types;
import miners.runner;
import miners.viewer;
import miners.options;
import miners.menu.base;
import miners.menu.main;
import miners.menu.beta;
import miners.menu.error;
import miners.menu.classic;


/**
 * Menu runner
 */
class MenuRunner : public Runner
{
public:
	Router router;
	Options opts;

protected:
	Runner levelRunner;

	GfxTextureTarget menuTexture;
	GfxDraw d;

	Button currentButton;
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

		keyboard.down ~= &this.keyDown;
		d = new GfxDraw();

		auto m = new MainMenu(this);
		changeWindow(m);
	}

	~this()
	{
		keyboard.down.disconnect(&this.keyDown);

		if (menu !is null)
			menu.breakApart();
		delete ih;
		delete levelRunner;

		if (menuTexture !is null)
			menuTexture.dereference();
	}

	void close()
	{
		if (levelRunner !is null)
			levelRunner.close();
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
		if (ticker !is null)
			ticker();
	}

	void render(GfxRenderTarget rt)
	{
		if (levelRunner !is null)
			levelRunner.render(rt);

		if (menuTexture is null)
			return;

		if (repaint) {
			if (menuTexture !is null)
				menuTexture.dereference();

			menu.paint();

			menuTexture = menu.getTarget();
			repaint = false;
		}

		menu.x = (rt.width - menuTexture.width) / 2;
		menu.y = (rt.height - menuTexture.height) / 2;

		d.target = rt;
		d.start();

		if (levelRunner is null) {
			auto t = opts.dirt();
			d.blit(t, Color4f(1, 1, 1, 1), false,
				0, 0, rt.width / 2, rt.height / 2,
				0, 0, rt.width, rt.height);
			//d.fill(Color4f(0, 0, 0, 1), false, 0, 0, rt.width, rt.height);
		}

		d.blit(menuTexture, menu.x, menu.y);
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

	/**
	 * A runner just deleted itself.
	 */
	void notifyDelete(Runner r)
	{
		if (levelRunner is r)
			levelRunner = null;
	}


	/*
	 *
	 * Misc
	 *
	 */


	void connect(char[] usr, char[] pwd, ClassicServerInfo csi)
	{
		changeWindow(new WebpageInfoMenu(this, usr, pwd, csi));
	}

	void connect(ClassicServerInfo csi)
	{
		changeWindow(new ClassicConnectingMenu(this, csi));
	}

	void displayError(Exception e, bool panic)
	{
		// Always handle exception via the game exception.
		auto ge = cast(GameException)e;
		if (ge is null)
			ge = new GameException(null, e);


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

		displayError(texts, panic);
	}

	void displayError(char[][] texts, bool panic)
	{
		auto m = new ErrorMenu(this, texts, panic);
		changeWindow(m);
		errorMode = panic;
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

	void commonMenuBack(Button b)
	{
		changeWindow(new MainMenu(this));
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
		try {
			auto lm = new LevelMenu(this);
			changeWindow(lm);
		} catch (Exception e) {
			displayError(e, false);
		}
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

private:
	void keyDown(CtlKeyboard kb, int sym, dchar unicode, char[] str)
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

	void changeWindow(MenuBase mb)
	{
		if (menuTexture !is null) {
			menuTexture.dereference();
			menuTexture = null;
		}
		if (menu !is null)
			menu.breakApart();
		menu = mb;
		ih.setRoot(menu);

		if (menu is null)
			return;

		menu.paint();
		menu.repaintDg = &triggerRepaint;
		menuTexture = menu.getTarget();
	}

	void triggerRepaint()
	{
		repaint = true;
	}
}
