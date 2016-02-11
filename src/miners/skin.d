// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.skin;

import std.string : format;
import uri = std.uri;

import charge.charge;
import charge.util.png;

import miners.options;


/**
 * A threaded TCP connection to the minecraft.net servers. 
 */
class SkinDownloader : NetHttpConnection
{
private:
	// Server details
	const string hostname = "s3.amazonaws.com";
	const ushort port = 80;
	const string url = "/MinecraftSkins/%s.png";

	GfxWrappedTexture[string] store;
	string curSkin;
	Vector!(string) nextSkin;
	Options opts;

	mixin SysLogging;


public:
	this(Options opts)
	{
		this.opts = opts;
		super(hostname, port);
	}

	override void close()
	{
		auto a = store.values.dup;
		store = null;
		foreach(tex; a)
			sysReference(&tex, null);

		super.close();
	}

	override void doTick()
	{
		if (curSkin is null &&
		    !nextSkin.length)
			return;

		if (curSkin is null) {
			curSkin = nextSkin[nextSkin.length - 1];
			nextSkin.length = nextSkin.length - 1;
		}

		super.doTick();
	}

	GfxTexture getSkin(string name)
	{
		auto test = name in store;
		if (test !is null)
			return *test;


		nextSkin ~= name;
		auto str = format("playerSkin/%s.png", name);
		auto ret = GfxWrappedTexture(SysPool(), str, opts.defaultSkin());
		store[name] = ret;
		return ret;
	}

	void httpGetSkin(string name)
	{
		auto url = format(this.url, name);
		httpGet(url);
	}

	override void handleError(Exception e)
	{
		curSkin = null;
		super.close();
	}

	override void handleResponse(char[] header, char[] res)
	{
		auto str = format("dl/%s.png", curSkin);
		l.info("%s", str);
		try {
			auto img = pngDecode(res, true);
			if (img is null)
				throw new Exception("Image format not supported");

			auto pic = Picture(img);
			scope(exit)
				sysReference(&pic, null);

			if (pic is null)
				throw new Exception("Failed create picture");

			auto tex = GfxTexture(pic);
			scope(exit)
				sysReference(&tex, null);

			if (tex is null)
				throw new Exception("Failed create texture");

			tex.filter = GfxTexture.Filter.Nearest;
			auto w = store[curSkin];
			w.update(tex);

		} catch (Exception e) {
			l.warn("%s", e.toString());
		}

		curSkin = null;
		super.close();
	}

	override void handleUpdate(int percentage)
	{
	}

	override void handleConnected()
	{
		httpGetSkin(curSkin);
	}

	override void handleDisconnect()
	{
		curSkin = null;
		l.warn("Got disconnected");
	}
}
