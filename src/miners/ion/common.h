#ifndef COMMON_H
#define COMMON_H

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>

#include "dcpu16ins.h"
//#include "log.h"
#include "cvector.h"

extern int logLevel;
typedef enum {DBO_LittleEndian, DBO_BigEndian } DByteOrder;

uint16_t GetUsedRam(uint16_t* ram);
void DumpRam(uint16_t* ram, uint16_t end);
void WriteRam(uint16_t* ram, const char* filename, uint16_t len);
void LoadRam(uint16_t* ram, const char* filename);
bool opHasNextWord(uint16_t v);
char* StrReplace(char* target, const char* str, const char* what, const char* with);
long FileSize(const char* filename);
int LoadRamMax(uint16_t* ram, const char* filename, uint16_t lastAddr, DByteOrder bo);

#endif
