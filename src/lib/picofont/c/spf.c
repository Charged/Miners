/* sdl_picofont

   http://nurd.se/~noname/sdl_picofont

   File authors:
      Fredrik Hultin

   License: GPLv2
*/


#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */


#include "SDL_picofont.h"

#include <stdlib.h>
#include <string.h>

#define FNT_FONTHEIGHT 8
#define FNT_FONTWIDTH 8

void FNT_GetFontSize(unsigned int *w, unsigned int *h)
{
	if (w)
		*w = FNT_FONTWIDTH;
	if (h)
		*h = FNT_FONTHEIGHT;
}

typedef struct
{
	int x;
	int y;
}FNT_xy;

FNT_xy FNT_Generate(const char* text, unsigned int len, unsigned int w, unsigned char* pixels, char value)
{
	unsigned int i, x, y, col, row, stop;
	unsigned char *fnt, chr;
	FNT_xy xy;

	fnt = FNT_GetFont();

	xy.x = xy.y = col = row = stop = 0;

	for(i = 0; i < len; i++){
		switch(text[i]){
			case '\n':
				row++;
				col = 0;
				chr = 0;
				break;

			case '\r':
				chr = 0;
				break;

			case '\t':
				chr = 0;
				col += 4 - col % 4;
				break;
		
			case '\0':
				stop = 1;
				chr = 0;
				break;
	
			default:
				col++;
				chr = text[i];
				break;
		}

		if(stop){
			break;
		}

		if((col + 1) * FNT_FONTWIDTH > (unsigned int)xy.x){
			xy.x = col * FNT_FONTWIDTH;
		}
		
		if((row + 1) * FNT_FONTHEIGHT > (unsigned int)xy.y){
			xy.y = (row + 1) * FNT_FONTHEIGHT;
		}

		if(chr != 0 && w != 0){
			for(y = 0; y < FNT_FONTHEIGHT; y++){
				for(x = 0; x < FNT_FONTWIDTH; x++){
					unsigned char c = (unsigned char)text[i];
					if(fnt[c * FNT_FONTHEIGHT + y] >> (7 - x) & 1){
						pixels[((col - 1) * FNT_FONTWIDTH) + x + (y + row * FNT_FONTHEIGHT) * w] = value;
					}
				}
			}
		}
	}

	return xy;
}

unsigned char* FNT_Render(const char* text, unsigned int *w, unsigned int *h)
{
	return FNT_RenderMax(text, strlen(text), w, h);
}

void FNT_BuildSize(const char* text, unsigned int len, unsigned int *w, unsigned int *h)
{
	FNT_xy xy;

	xy = FNT_Generate(text, len, 0, NULL, 0);

	*w = xy.x;
	*h = xy.y;
}

unsigned char* FNT_RenderMax(const char* text, unsigned int len, unsigned int *w, unsigned int *h)
{
	unsigned char* pixels;
	FNT_xy xy;

	xy = FNT_Generate(text, len, 0, NULL, 0);

	pixels = malloc(xy.x * xy.y);
	if (!pixels)
		return NULL;
	memset(pixels, 0, xy.x * xy.y);

	FNT_Generate(text, len, xy.x, pixels, 0xff);

	*w = xy.x;
	*h = xy.y;

	return pixels;
}


#ifdef __cplusplus
};
#endif /* __cplusplus */
