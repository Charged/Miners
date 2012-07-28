// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.gfx.sync;

import charge.gfx.gl;


// Prefix already added.
typedef void* GfxSync;

bool gfxSyncWaitAndDelete(ref GfxSync sync, long timeout)
{
	if (sync is null)
		return true;

	auto tm = timeout * 1000;
	if (tm < 0)
		tm = 0;

	auto ret = glClientWaitSync(sync, GL_SYNC_FLUSH_COMMANDS_BIT, cast(ulong)tm);

	switch(ret) {
	case GL_ALREADY_SIGNALED:
	case GL_CONDITION_SATISFIED:
		glDeleteSync(sync);
		sync = null;
		return true;
	case GL_WAIT_FAILED:
		gluGetError("gfxSyncWait");
	default:
		return false;
	}
}

void gfxSyncDelete(ref GfxSync sync)
{
	if (sync !is null)
		glDeleteSync(sync);
	sync = null;
}

GfxSync gfxSyncInsert()
{
	if (!GL_ARB_sync)
		return null;

	return cast(GfxSync)glFenceSync(GL_SYNC_GPU_COMMANDS_COMPLETE, 0);
}
