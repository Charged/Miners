module lib.picofont.pico;


extern (C):

ubyte* FNT_Render(char* text, uint *w, uint *y);
ubyte* FNT_RenderMax(char* text, uint len, uint *w, uint *y);

void FNT_GetFontSize(uint *w, uint *h);
void* FNT_GetFont();


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
