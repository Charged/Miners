#include "common.h"

void WriteRam(uint16_t* ram, const char* filename, uint16_t end)
{
	FILE* out = fopen(filename, "w");
	int i;

	for(i = 0; i < end + 1; i++){
		fputc(ram[i] & 0xff, out);
		fputc(ram[i] >> 8, out);
	}

	fclose(out);
}

int LoadRamMax(uint16_t* ram, const char* filename, uint16_t lastAddr, DByteOrder bo)
{
	FILE* f = fopen(filename, "r");

	int addr = 0;

	for(;;){
		int c1 = 0, c2 = 0;
		if((c1 = fgetc(f)) == EOF || (c2 = fgetc(f)) == EOF) break;
		if(bo == DBO_LittleEndian) 	ram[addr] = (c2 & 0xff) << 8 | (c1 & 0xff);
		else 				ram[addr] = (c1 & 0xff) << 8 | (c2 & 0xff);
		if(addr >= lastAddr) break;
		addr++;
	}

	fclose(f);

	return (int)addr + 1;
}

void LoadRam(uint16_t* ram, const char* filename)
{
	LoadRamMax(ram, filename, 0xffff, DBO_LittleEndian);
}

uint16_t GetUsedRam(uint16_t* ram)
{
	int end = 0xffff;
	while(ram[--end] == 0);
	return end;
}

void DumpRam(uint16_t* ram, uint16_t end)
{
	int i;

	for(i = 0; i < end + 1; i++){
		if(i % 8 == 0) printf("\n%04x: ", i);
		printf("%04x ", ram[i]);
	}

	printf("\n\n");
}

bool opHasNextWord(uint16_t v){ 
	return (v >= DV_RefRegNextWordBase && v <= DV_RefRegNextWordTop)
		|| v == DV_RefNextWord || v == DV_NextWord; 
}

char* StrReplace(char* target, const char* str, const char* what, const char* with)
{
	const char* ss = strstr(str, what);

	if(!ss) strcpy(target, str);
	else{
		int at = (intptr_t)ss - (intptr_t)str;
			
		strncpy(target, str, at);
		strcpy(target + at, with);
		strcpy(target + at + strlen(with), str + at + strlen(what));
	}

	return target;
}

