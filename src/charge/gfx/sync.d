// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for syncing with the gpu.
 */
module charge.gfx.sync;

import charge.gfx.gl;


/**
 * Sync object.
 *
 * Prefix already added.
 */
alias void* GfxSync;

/**
 * Sync with the gpu and delete sync object or timeout happens, in milliseconds.
 */
bool gfxSyncWaitAndDelete(ref GfxSync sync, long timeout)
{
	if (sync is null)
		return true;

	auto tm = timeout * 1000 * 1000;
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
		goto default;
	default:
		return false;
	}
}

/**
 * Delete a sync object.
 */
void gfxSyncDelete(ref GfxSync sync)
{
	if (sync !is null)
		glDeleteSync(sync);
	sync = null;
}

/**
 * Insert a sync object into the GPU command stream.
 */
GfxSync gfxSyncInsert()
{
	if (!GL_ARB_sync)
		return null;

	return cast(GfxSync)glFenceSync(GL_SYNC_GPU_COMMANDS_COMPLETE, 0);
}
