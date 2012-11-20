// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for windows specific interfaces.
 */
module charge.platform.windows;

version(Windows):

import std.string : toStringz;
import std.c.windows.windows;


const uint CF_TEXT = 1;

extern(Windows) BOOL IsClipboardFormatAvailable(
		UINT uFormat
	);

extern(Windows) BOOL OpenClipboard(
		HWND hWndNewOwner
	);

extern(Windows) BOOL CloseClipboard();

extern(Windows) HANDLE GetClipboardData(
 		UINT uFormat
	);

extern(Windows) LPVOID GlobalLock(
		HGLOBAL hMem
	);

extern(Windows) BOOL GlobalUnlock(
		HGLOBAL hMem
	);

extern(Windows) size_t GlobalSize(
		HGLOBAL hMem
	);


char[] getClipboardText()
{
	auto format = CF_TEXT;

	auto bRet = IsClipboardFormatAvailable(format);
	if (!bRet)
		return null;

	bRet = OpenClipboard(null);
	if (!bRet)
		return null;

	scope(exit) {
		bRet = CloseClipboard();
		assert(bRet, "Could not close clipboard");
	}

	auto hMem = GetClipboardData(format);
	if (hMem is null)
		return null;

	auto src = cast(char *)GlobalLock(hMem);
	if (src is null)
		return null;

	scope(exit) {
		bRet = GlobalUnlock(hMem);
		assert(bRet, "Could not unlock global memory");
	}

	// Somebody is going to do something bad I'm sure of it.
	auto size = GlobalSize(hMem);
	foreach(size_t i, c; src[0..size]) {
		if (c == '\0') {
			size = i;
			break;
		}
	}

	return src[0 .. size].dup;
}

void panicMessage(string str)
{
	auto ptr = toStringz(str);
	MessageBoxA(null, ptr, "Core Panic!", MB_OK);
}
