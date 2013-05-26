// Copyright © 2013, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.sfx.all;

public {
	static import charge.sfx.sfx;
	static import charge.sfx.buffer;
	static import charge.sfx.buffermanager;
	static import charge.sfx.listener;
	static import charge.sfx.source;
}

alias charge.sfx.sfx.sfxLoaded sfxLoaded;
alias charge.sfx.buffer.Buffer SfxBuffer;
alias charge.sfx.buffermanager.BufferManager SfxBufferManager;
alias charge.sfx.listener.Listener SfxListener;
alias charge.sfx.source.Source SfxSource;
