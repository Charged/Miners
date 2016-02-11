// Copyright © 2013, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for UpdateScene class.
 */
module charge.game.scene.update;

import charge.game.gui.text;
import charge.game.gui.container;
import charge.game.update;
import charge.game.scene.menu;


/**
 * A helper scene that manages a UpdateDownloader
 */
abstract class UpdateScene : MenuScene
{
protected:
	UpdateDownloader ud;


public:
	this(TextureContainer target,
	     string hostname, ushort port,
	     string localPath, string serverPath,
	     string versionFilename, string[] files)
	{
		ud = new UpdateDownloader(hostname, port,
			localPath, serverPath,
			versionFilename, files);
		ud.updateDg = &update;
		ud.errorDg = &doError;
		ud.doneDg = &doDone;

		super(target);
	}

	override void close()
	{
		if (ud !is null) {
			ud.close();
			ud = null;
		}
		super.close();
	}

	override void logic()
	{
		if (ud !is null)
			ud.logic();
	}


protected:
	abstract void done();
	abstract void error(Exception e);
	abstract void update(int p, string file);


private:
	// To manage ud completely in this class.
	void doDone()
	{
		ud = null;
		done();
	}

	// To manage ud completely in this class.
	void doError(Exception e)
	{
		ud = null;
		error(e);
	}
}
