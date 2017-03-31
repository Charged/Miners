// Copyright © 2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Helper file during transition to D2.
 */
module stdx.file;

static import std.file;


bool isFile(const(char)[] file)
{
	try {
		return std.file.isFile(file);
	} catch (Exception) {
		return false;
	}
}

bool isDir(const(char)[] file)
{
	try {
		return std.file.isDir(file);
	} catch (Exception) {
		return false;
	}
}
