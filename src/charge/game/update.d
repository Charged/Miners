// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for version handling of files.
 */
module charge.game.update;

import std.file : read, write, exists;
import std.string : format;
import std.stream : BufferedFile, FileMode;
import stdx.regexp : RegExp;
import stdx.string : splitlines, toString;

import charge.net.download;


/**
 * Represents both a local and server version txt file.
 */
class VersionTxt
{
public:
	const string commentRegexStr = `^\s*#`;
	const string nameRegexStr = `^(\S+)\s*$`;
	const string md5AndNameRegexStr = `\s*([a-fA-F0-9]{32})\s+(\S+)\s*$`;

	class File
	{
		/// Name on disk
		string local;
		/// Name on the server (for local files this is null)
		string server;
		/// Md5 sum of file
		string md5;

		this(string local, string server, string md5)
		{
			this.local = local;
			this.server = server;
			this.md5 = md5;
		}
	}


private:
	File[string] store;


public:
	void add(string local, string server, string md5)
	{
		store[local] = new File(local, server, md5);
	}

	/**
	 * Removes files that we are interested in from the store
	 * if they do not exists in the given path.
	 */
	void pruneNonExisting(string path, string[] files)
	{
		foreach(file; files) {
			if ((file in store) !is null &&
			    !exists(path ~ file))
				store.remove(file);
		}
	}

	static File[] getListOfFiles(VersionTxt local, VersionTxt server, string[] files)
	{
		File[] ret;

		foreach(file; files) {

			// Can only do things to files on the server.
			if ((file in server.store) is null)
				throw new Exception("File not listed on server");

			// Update if not in the local store, or if different md5.
			auto fileServer = server.store[file];
			if ((file in local.store) is null ||
			    local.store[file].md5 != fileServer.md5) {

				ret ~= fileServer;
			}
		}

		return ret;
	}

	bool saveLocal(string filename)
	{
		BufferedFile f;

		try {
			f = new BufferedFile(filename, FileMode.OutNew);
		} catch (Exception e) {
			return false;
		}

		foreach(v; store.values) {
			f.writefln(v.md5, "  ", v.local);
		}
		f.flush();
		f.close();

		return true;
	}

	static VersionTxt fromServer(const(char)[] text)
	{
		auto ver = new VersionTxt();
		auto commentRegex = new RegExp(commentRegexStr);
		auto nameRegex = new RegExp(nameRegexStr);
		auto md5AndNameRegex = new RegExp(md5AndNameRegexStr);

		string name;
		bool nameFound;

		foreach(int i, line; splitlines(text)) {

			// Skip the first line
			if (i == 0)
				continue;

			// Skip empty and comments lines
			if (line.length == 0 || commentRegex.match(cast(string)line).length > 0)
				continue;

			if (!nameFound) {
				auto m = nameRegex.match(cast(string)line);
				if (m.length < 2)
					throw new Exception("Parse error, line: " ~ .toString(i));
				nameFound = true;
				name = m[1].idup;
			} else {
				auto m = md5AndNameRegex.match(cast(string)line);
				if (m.length < 3)
					throw new Exception("Parse error, line: " ~ .toString(i));
				nameFound = false;

				ver.add(name, m[2].idup, m[1].idup);
			}
		}

		return ver;
	}

	static VersionTxt fromLocal(const(char)[] text)
	{
		auto ver = new VersionTxt();
		auto commentRegex = new RegExp(commentRegexStr);
		auto md5AndNameRegex = new RegExp(md5AndNameRegexStr);

		string name;
		bool nameFound;

		foreach(int i, line; splitlines(text)) {

			// Skip empty and comments lines
			if (line.length == 0 || commentRegex.match(cast(string)line).length > 0)
				continue;

			auto m = md5AndNameRegex.match(cast(string)line);
			if (m.length < 2)
				throw new Exception("Parse error, line: " ~ .toString(i));

			ver.add(m[2].idup, null, m[1].idup);
		}

		return ver;
	}
}

/**
 * A downloader that automatically figures out which
 * files to download.
 */
class UpdateDownloader : DownloadListener
{
public:
	void delegate(int p, string file) updateDg;
	void delegate(Exception e) errorDg;
	void delegate() doneDg;

protected:
	string hostname;
	ushort port;

	string localPath;
	string serverPath;
	string versionFilename;
	string[] files;

	VersionTxt local;
	VersionTxt server;
	VersionTxt.File[] toDownload;

	// Currently downloading file.
	VersionTxt.File thisDownload;
	string thisFile;


	DownloadConnection dc;


public:
	this(string hostname, ushort port,
	     string localPath, string serverPath,
	     string versionFilename, string[] files)
	{
		if (localPath !is null &&
		    localPath[$-1] != '/')
			localPath = localPath ~ "/";

		if (serverPath is null)
			serverPath = "/";
		else if (serverPath[0] != '/')
			serverPath = "/" ~ serverPath;

		if (serverPath[$-1] != '/')
			serverPath = serverPath ~ "/";


		this.files = files;
		this.localPath = localPath;
		this.serverPath = serverPath;
		this.versionFilename = versionFilename;

		try {
			auto txt = cast(char[])read(versionFilename);
			local = VersionTxt.fromLocal(txt);

			// Always download removed files.
			local.pruneNonExisting(localPath, files);

		} catch (Exception e) {
			local = new VersionTxt();
		}

		dc = new DownloadConnection(this, hostname, port);
	}

	void close()
	{
		shutdownConnection();
	}

	void logic()
	{
		if (dc !is null)
			dc.doTick();
		else if (doneDg !is null)
			doneDg();
	}


protected:
	void shutdownConnection()
	{
		if (dc !is null) {
			dc.close();
			delete dc;
		}
	}

	void connected()
	{
		thisFile = server is null ? versionFilename : thisDownload.local;

		dc.getDownload(serverPath ~ thisFile);

		percentage(0);
	}

	void percentage(int p)
	{
		if (updateDg !is null)
			updateDg(p, thisFile);
	}

	void downloaded(void[] data)
	{
		// Re use the connection.
		dc.close();

		// Update
		percentage(100);

		if (server is null) {
			server = VersionTxt.fromServer(cast(char[])data);
			toDownload = VersionTxt.getListOfFiles(local, server, files);
		} else {
			assert(thisDownload !is null);

			// Update
			local.add(thisDownload.local, thisDownload.server, thisDownload.md5);

			// Save file
			write(localPath ~ thisDownload.local, data);
		}

		if (toDownload.length == 0) {
			local.saveLocal(localPath ~ versionFilename);
			close();
			return;
		}

		thisDownload = toDownload[$-1];
		toDownload.length = toDownload.length - 1;
	}

	void error(Exception e)
	{
		errorDg(e);
		shutdownConnection();
	}

	void disconnected()
	{
		shutdownConnection();
	}
}
