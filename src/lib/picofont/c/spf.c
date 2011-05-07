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

FNT_xy FNT_Generate(const char* text, unsigned int len, unsigned int w, unsigned char* pixels)
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
					if(fnt[text[i] * FNT_FONTHEIGHT + y] >> (7 - x) & 1){
						pixels[((col - 1) * FNT_FONTWIDTH) + x + (y + row * FNT_FONTHEIGHT) * w] = 1;
					}
				}
			}
		}
	}

	return xy;
}

/* XXX: Not used */
#if 0
SDL_Surface* FNT_Render(const char* text, SDL_Color color)
{
	return FNT_RenderMax(text, strlen(text), color);
}

SDL_Surface* FNT_RenderMax(const char* text, unsigned int len, SDL_Color color)
{
	SDL_Surface* surface;
	SDL_Color colors[2];
	FNT_xy xy;

	colors[0].r = (color.r + 0x7e) % 0xff;
	colors[0].g = (color.g + 0x7e) % 0xff;
	colors[0].b = (color.b + 0x7e) % 0xff;

	colors[1] = color;

	xy = FNT_Generate(text, len, 0, NULL);

	surface = SDL_CreateRGBSurface(
			SDL_SWSURFACE, 
			xy.x,
			xy.y,
			8,
			0,
			0,
			0,
			0
	);

	if(!surface){
		return NULL;
	}

	SDL_SetColorKey(surface, SDL_SRCCOLORKEY, SDL_MapRGB(surface->format, (color.r + 0x7e) % 0xff, (color.g + 0x7e) % 0xff, (color.b + 0x7e) % 0xff));
	/*SDL_FillRect(surface, NULL, SDL_MapRGB(surface->format, 0x0d, 0xea, 0xd0));*/

	SDL_SetColors(surface, colors, 0, 2);


	if(SDL_MUSTLOCK(surface)){
		SDL_LockSurface(surface);
	}

	FNT_Generate(text, len, surface->w, (unsigned char*)surface->pixels);
	
	if(SDL_MUSTLOCK(surface)){
		SDL_UnlockSurface(surface);
	}

	return surface;
}
#endif

#ifdef __cplusplus
};
#endif /* __cplusplus */
