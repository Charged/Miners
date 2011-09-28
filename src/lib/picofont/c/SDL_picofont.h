/* sdl_picofont

   http://nurd.se/~noname/sdl_picofont

   File authors:
      Fredrik Hultin

   License: GPLv2
*/

#ifndef SDL_PICOFONT_H
#define SDL_PICOFONT_H

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */


unsigned char* FNT_Render(const char* text, unsigned int *w, unsigned int *h);
unsigned char* FNT_RenderMax(const char* text, unsigned int len, unsigned int *w, unsigned int *h);

void FNT_BuildSize(const char* text, unsigned int len, unsigned int *w, unsigned int *h);

void FNT_GetFontSize(unsigned int *w, unsigned int *h);
unsigned char* FNT_GetFont();


#ifdef __cplusplus
};
#endif /* __cplusplus */

#endif /* SDL_PICOFONT_H */
