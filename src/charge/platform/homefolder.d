module charge.platform.homefolder;

import std.c.stdlib;
import std.string;

char[] homeFolder;
char[] applicationConfigFolder;
char[] chargeConfigFolder;

static this()
{
	version(linux) {
		homeFolder = toString(getenv("HOME"));
		applicationConfigFolder = homeFolder ~ "/.config";
	} else version(darwin) {
		// TODO Not tested
		homeFolder = toString(getenv("HOME"));
		applicationConfigFolder = homeFolder ~ "/Library/Application Support";
	} else version(Windows) {
		// TODO Not tested
		homeFolder = toString(getenv("USERPROFILE"));
		applicationConfigFolder = toString(getenv("APPDATA"));
	} else {
		static assert(false);
	}

	chargeConfigFolder = applicationConfigFolder ~ "/charge";
}
