// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for logging class Logger and helpers.
 */
module charge.sys.logger;

import std.stdio : FILE, FPUTC, stdout, fopen, fflush, fprintf;
import std.string : format, rfind;
import std.format : doFormat;
import std.stdarg; // Oh god DMD.
import std.utf : toUTF8;

import charge.platform.homefolder;


enum Level
{
	Trace = 0,
	Debug = 1,
	Info  = 2,
	Warn  = 3,
	Error = 4,
	Fatal = 5
}

private string[] TextLevels = [
	"<TT>",
	"<DD>",
	"<II>",
	"<WW>",
	"<EE>",
	"<!!>"
];


interface Writer
{
	void log(ClassInfo info, Level level, TypeInfo[] arguments, va_list argptr);
}

/**
 * Convinence template for classes.
 */
template Logging()
{
	static charge.sys.logger.Logger l;

	static this()
	{
		l = charge.sys.logger.Logger(this.classinfo);
	}
}

private class StdOutWriter : Writer
{
private:
	FILE *file;
public:
	static this()
	{
		instance = new StdOutWriter();
	}

	this()
	{
		auto n = format("%s/log.txt\0", chargeConfigFolder);
		file = fopen(n.ptr, "w");

		if (file is null)
			file = stdout;
		else
			fprintf(file, "%s Logger: Opened log\n", TextLevels[Level.Info].ptr);
		fflush(file);
	}

	void log(ClassInfo info, Level level, TypeInfo[] arguments, va_list argptr)
	{
		string name = info.name;
		name = name[cast(size_t)(rfind(name, '.') + 1) .. length];

		fprintf(file, "%s %.*s: ", TextLevels[level].ptr, cast(uint)name.length, name.ptr);
		writefx(arguments, argptr, true);
		fflush(file);
	}

	void writefx(TypeInfo[] arguments, va_list argptr, bool newline = false)
	{
		// Ugly work around for not being able to call FLOCK and FUNLOCK
		version(Linux) {
			FLOCK(stdout);
			scope(exit) FUNLOCK(stdout);
		}

		void putc(dchar c)
		{
			if (c <= 0x7F) {
				FPUTC(c, file);
			} else {
				char[4] buf;
				char[] b;

				b = toUTF8(buf, c);
				for (size_t i = 0; i < b.length; i++)
					FPUTC(b[i], file);
			}
		}

		doFormat(&putc, arguments, argptr);

		if (newline)
			FPUTC('\n', file);
	}

	static Writer instance;
}

class Logger
{
	static Logger opCall(ClassInfo c)
	{
		return new Logger(c);
	}

	this(ClassInfo c)
	{
		this.c = c;
		this.w = StdOutWriter.instance;
		this.l = Level.Debug;
	}

	void trace(...)
	{
		if (isTrace)
			forceLog(Level.Trace, _arguments, _argptr);
	}

	void bug(...)
	{
		if (isDebug)
			forceLog(Level.Debug, _arguments, _argptr);
	}

	void info(...)
	{
		if (isInfo)
			forceLog(Level.Info, _arguments, _argptr);
	}

	void warn(...)
	{
		if (isWarn)
			forceLog(Level.Warn, _arguments, _argptr);
	}

	void error(...)
	{
		if (isError)
			forceLog(Level.Error, _arguments, _argptr);
	}

	void fatal(...)
	{
		if (isFatal)
			forceLog(Level.Fatal, _arguments, _argptr);
	}

	int level()
	{
		return l;
	}

	bool isTrace()
	{
		return l <= Level.Trace;
	}

	bool isDebug()
	{
		return l <= Level.Debug;
	}

	bool isInfo()
	{
		return l <= Level.Info;
	}

	bool isWarn()
	{
		return l <= Level.Warn;
	}

	bool isError()
	{
		return l <= Level.Error;
	}

	bool isFatal()
	{
		return l <= Level.Fatal;
	}

protected:

	void forceLog(Level level, TypeInfo[] arguments, va_list argptr)
	{
		w.log(c, level, arguments, argptr);
	}

private:
	Writer w;
	ClassInfo c;
	Level l;
	Level current;
}

