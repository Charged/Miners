module lib.al.al;

import lib.loader;

public:
import lib.al.types;
import lib.al.al11;
import lib.al.alc;
import lib.al.alut;

void loadAL(Loader l)
{
	loadFunc!(alGetProcAddress)(l);

	if (alGetProcAddress is null)
		return;

	loadAL11(l);
	loadALC(l);
}
