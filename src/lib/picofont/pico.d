module lib.picofont.pico;


// TODO: More functions


extern (D):

char[] licenseText = `
/* sdl_picofont

   http://nurd.se/~noname/sdl_picofont

   File authors:
      Fredrik Hultin

   With code from:
      Greg Harp
      John Shifflett

   License: GPLv2
*/
`;

import license;

static this()
{
	licenseArray ~= licenseText;
}
