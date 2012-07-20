// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.classic.startup;

import std.string : format, find;

import lib.gl.gl;

import charge.charge;
import charge.math.ints;
import charge.game.gui.text;
import charge.game.gui.textbased;
import charge.game.gui.messagelog;

import miners.logo;
import miners.types;
import miners.runner;
import miners.options;
import miners.interfaces;
import miners.classic.webpage;


/**
 * Classic runner
 */
class ClassicStartup : public Runner, public ClassicWebpageListener
{
private:
	Router r;
	Options opts;

	mixin SysLogging;
	CtlKeyboard keyboard;
	CtlMouse mouse;

	GfxDraw d;
	Text statusText;
	GfxTexture logo;


	char[] playSession;
	WebpageConnection wc;

	const string connectingString = "Connecting...";
	const string retrievingString = "Retrieving server list: %s%%";

public:
	this(Router r, Options opts)
	{
		super(Type.Game);
		this.r = r;
		this.opts = opts;

		keyboard = CtlInput().keyboard;
		mouse = CtlInput().mouse;

		createLogo();
		createBackground();

		d = new GfxDraw();

		statusText = new Text(null, 0, 0, connectingString);

		playSession = opts.playSessionCookie();
		wc = new WebpageConnection(this, playSession);
	}

	~this()
	{
		assert(wc is null);
	}

	void close()
	{
		if (statusText !is null) {
			statusText.breakApart();
			statusText = null;
		}

		shutdownConnection();

		sysReference(&logo, null);
	}

	void logic()
	{
		if (wc !is null)
			wc.doEvents();
	}

	void render(GfxRenderTarget rt)
	{
		d.target = rt;
		d.start();

		glClearColor(0, 0, 0, 0);
		glClear(GL_COLOR_BUFFER_BIT);

		if (logo !is null) {
			int x = (rt.width - logo.width) / 2;
			int y = (rt.height - logo.height) / 2;

			d.blit(logo, Color4f.White, true, x, y);
		}

		if (statusText !is null) {
			int x = rt.width - cast(int)retrievingString.length * gfxDefaultFont.width - 8;
			int y = rt.height - 16;

			d.translate(x, y);

			statusText.paint(d);
		}

		d.stop();
	}

	void assumeControl()
	{
		keyboard.down ~= &this.keyDown;
	}

	void dropControl()
	{
		keyboard.down -= &this.keyDown;
	}

	void resize(uint w, uint h)
	{

	}

protected:
	void createLogo()
	{
		auto logo = new Logo(null, 0, 0);
		auto aat = new AntiAliasingContainer(null, 0, 0, logo.w, logo.h);
		auto tt = new TextureContainer(logo.w, logo.h);

		aat.add(logo);
		tt.add(aat);

		aat.paintTexture();
		tt.paintTexture();

		sysReference(&this.logo, tt.texture);

		tt.breakApart();
	}

	void createBackground()
	{
		auto cog = new Cogwheel(null, 0, 0, 32, 32, 26, 12);
		auto aat = new AntiAliasingContainer(null, 0, 0, cog.w, cog.h);
		auto tt = new TextureContainer(cog.w, cog.h);

		aat.add(cog);
		tt.add(aat);

		aat.paintTexture();
		tt.paintTexture();

		opts.background = tt.texture;
		opts.backgroundDoubled = false;

		tt.breakApart();
	}


	/*
	 *
	 * Input functions.
	 *
	 */


	void keyDown(CtlKeyboard kb, int sym, dchar unicode, char[] str)
	{
		if (sym != 27)
			return;

		shutdownConnection();
		r.quit();
	}


	/*
	 *
	 * Webpage related functions.
	 *
	 */


	void shutdownConnection()
	{
		if (wc !is null) {
			try {
				wc.close();
			} catch (Exception e) {
				cast(void)e;
			}

			delete wc;
		}
	}

	void percentage(int p)
	{
		statusText.setText(format(retrievingString, p));
	}

	void authenticate()
	{
		assert("Can not authenticate!" is null);
	}

	void getServerList()
	{
		wc.getServerList();

		percentage(0);
	}


	/*
	 *
	 * Webpage connection callbacks
	 *
	 */


	void connected()
	{
		if (playSession is null)
			authenticate();
		else
			getServerList();
	}

	void authenticated()
	{
		getServerList();
	}

	void serverList(ClassicServerInfo[] csis)
	{
		shutdownConnection();

		r.displayClassicList(csis);
		r.deleteMe(this);
	}

	void serverInfo(ClassicServerInfo csi)
	{
		assert("Can not authenticate!" is null);
	}

	void error(Exception e)
	{
		shutdownConnection();

		r.displayError(["Disconnected", e.toString()], false);
		r.deleteMe(this);
	}

	void disconnected()
	{
		// The server closed the connection peacefully.
		shutdownConnection();

		r.displayError(["Disconnected"], false);
		r.deleteMe(this);
	}
}
