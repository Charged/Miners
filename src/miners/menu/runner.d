// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.menu.runner;

import miners.error;
import miners.types;
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
class MenuRunner : public MenuManager
{
public:
	Router r;
	Options opts;

public:
	this(Router r, Options opts)
	{
		this.r = r;
		this.opts = opts;
	}


	/*
	 *
	 * MenuManager functions.
	 *
	 */


	void displayMainMenu()
	{
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
}
