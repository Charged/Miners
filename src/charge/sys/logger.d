// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.sys.logger;

import std.stdio;
import std.string;
import std.stdarg;

enum Level
{
	Trace = 0,
	Debug = 1,
	Info  = 2,
	Warn  = 3,
	Error = 4,
	Fatal = 5
}

private char[][] TextLevels = [
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

private class StdOutWriter : public Writer
{
public:
	static this()
	{
		instance = new StdOutWriter();
	}

	void log(ClassInfo info, Level level, TypeInfo[] arguments, va_list argptr)
	{
		char[] name = info.name;
		name = name[cast(size_t)(rfind(name, '.') + 1) .. length];

		writef(TextLevels[level], " ", name, ": ");
		writefx(arguments, argptr, true);
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
				FPUTC(c, stdout);
			} else {
				char[4] buf;
				char[] b;

				b = std.utf.toUTF8(buf, c);
				for (size_t i = 0; i < b.length; i++)
					FPUTC(b[i], stdout);
			}
    	}

		std.format.doFormat(&putc, arguments, argptr);

		if (newline)
			FPUTC('\n', stdout);
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
		this.l = Level.Warn;
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

