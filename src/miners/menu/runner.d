// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.menu.runner;

import charge.charge;
import charge.game.gui.input;
import charge.game.gui.textbased;

import miners.runner;
import miners.viewer;
import miners.menu.main;
import miners.menu.beta;
import miners.menu.error;


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
	bool repaint;

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

		if (repaint) {
			if (menuTexture !is null)
				menuTexture.dereference();

			tc.paint();

			menuTexture = tc.getTarget();
			repaint = false;
		}

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
		tc.repaintDg = &triggerRepaint;
		menuTexture = tc.getTarget();
	}

	void triggerRepaint()
	{
		repaint = true;
	}
}
