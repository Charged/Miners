// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// Code heavily based on code in phobos that was in Public Domain.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for Zip file and zlib functions.
 */
module charge.util.zip;

import etc.c.zlib;

import core.bitop : bswap;
import charge.util.memory;

// Reuse Exceptions from Phobos
public import std.zip : ZipException;
public import std.zlib : ZlibException;


/**
 * Uncompress the given buffer.
 *
 * Return a C allocated memory array. 
 */
void[] cUncompress(void[] srcbuf, size_t destlen = 0u, int winbits = 15)
{
	etc.c.zlib.z_stream zs;

	size_t destpos;
	void *dest;
	int err;

	destlen = 5;

	// If we throw something free the C pointer.
	scope(failure)
		cFree(dest);

	if (!destlen)
		destlen = srcbuf.length * 2 + 1;

	zs.next_in = cast(ubyte*)srcbuf.ptr;
	zs.avail_in = cast(uint)srcbuf.length;

	err = etc.c.zlib.inflateInit2(&zs, winbits);
	if (err)
		throw new ZlibException(err);

	while(1) {
		dest = cRealloc(dest, destlen);
		zs.next_out = cast(ubyte*)(dest + destpos);
		zs.avail_out = cast(uint)(destlen - destpos);

		err = etc.c.zlib.inflate(&zs, Z_NO_FLUSH);
		switch (err) {
		// All done!
		case Z_STREAM_END:
			destpos = destlen - zs.avail_out;

			err = etc.c.zlib.inflateEnd(&zs);
			if (err)
				throw new ZlibException(err);

			return dest[0 .. destpos];

		// Errors!
		default:
			throw new ZlibException(err);

		// Need more input or output
		case Z_OK:
			// If we need more input throw a error.
			err = Z_BUF_ERROR;
			goto case Z_BUF_ERROR;
		// Might not be a error
		case Z_BUF_ERROR:
			// If we don't need more output we need input this is an error.
			if (zs.avail_out != 0)
				throw new ZlibException(err);
		}

		// Update the position and make sure we allocate more memory.
		destpos = destlen - zs.avail_out;
		destlen = destlen * 2 + 1;
	}
	assert(0);
}

/**
 * Accessor helpers.
 */
private template ZipHelpers()
{
	ushort getUshort(size_t i)
	{
		version (LittleEndian) {
			return *cast(ushort *)&data[i];
		} else {
			ubyte b0 = data[i];
			ubyte b1 = data[i + 1];
			return (b1 << 8) | b0;
		}
	}

	uint getUint(size_t i)
	{
		version (LittleEndian) {
			return *cast(uint *)&data[i];
		} else {
			return bswap(*cast(uint *)&data[i]);
		}
	}

	string getString(size_t i, size_t len) {
		return cast(string)data[i .. i + len];
	}
}

/**
 * Uncompress a file from the given archive.
 *
 * Return a C allocated memory array.
 */
void[] cUncompressFromFile(void[] srcbuf, string name)
{
	ubyte[] data = cast(ubyte[])srcbuf;
	long iend;
	size_t i;
	size_t endcommentlength;
	size_t directorySize;
	size_t directoryOffset;
	size_t endrecOffset;

	mixin ZipHelpers!();

	// Find 'end record index' by searching backwards for signature
	iend = cast(typeof(iend))data.length - 66000;
	if (iend < 0)
		iend = 0;

	for (i = data.length - 22; 1; i--) {
		if (i < iend)
			throw new ZipException("no end record");

		if (getString(i, 4) == "PK\x05\x06") {
			endcommentlength = getUshort(i + 20);
			if (i + 22 + endcommentlength > data.length)
				continue;
			endrecOffset = i;
			break;
		}
	}

	auto numEntries = getUshort(i + 8);
	auto totalEntries = getUshort(i + 10);

	if (numEntries != totalEntries)
		throw new ZipException("multiple disk zips not supported");

	directorySize = getUint(i + 12);
	directoryOffset = getUint(i + 16);

	if (directoryOffset + directorySize > i)
		throw new ZipException("corrupted directory");

	i = directoryOffset;
	for (int n = 0; n < numEntries; n++) {

		// Sanity check
		if (getString(i, 4) != "PK\x01\x02")
			throw new ZipException("invalid directory entry 1");

		auto compressedSize = getUint(i + 20);
		auto expandedSize = getUint(i + 24);
		auto namelen = getUshort(i + 28);
		auto extralen = getUshort(i + 30);
		auto commentlen = getUshort(i + 32);
		auto offset = getUint(i + 42);
		i += 46;

		if (i + namelen + extralen + commentlen > directoryOffset + directorySize)
			throw new ZipException("invalid directory entry 2");

		auto filename = getString(i, namelen);
		i += namelen;
		i += extralen;
		i += commentlen;

		// Is this the file we are looking for.
		if (filename != name)
			continue;

		return cUncompressFromEntry(data[offset .. $], compressedSize, expandedSize);
	}

	if (i != directoryOffset + directorySize)
		throw new ZipException("invalid directory entry 3");

	throw new ZipException("could not find compressed file");
}

void[] cUncompressFromEntry(void[] data, size_t compressedSize, size_t expandedSize)
{
	size_t i;

	mixin ZipHelpers!();

	if (getString(i, 4) != "PK\x03\x04")
		throw new ZipException("invalid directory");

	auto compressionMethod = getUshort(i + 8);
	auto namelen = getUshort(i + 26);
	auto extralen = getUshort(i + 28);

	i += 30;
	i += namelen;
	i += extralen;

	auto filedata = data[i .. i + compressedSize];

	switch (compressionMethod) {
		case 0:
			auto ptr = cMalloc(filedata.length);
			if (ptr is null)
				throw new ZipException("out of memory");
			ptr[0 .. filedata.length] = filedata[0 .. $];
			return ptr[0 .. filedata.length];
		case 8:
			// -15 is a magic value used to decompress zip files.
			// It has the effect of not requiring the 2 byte header
			// and 4 byte trailer.
			return cUncompress(filedata, expandedSize, -15);
		default:
			throw new ZipException("unsupported compression method");
	}
}
