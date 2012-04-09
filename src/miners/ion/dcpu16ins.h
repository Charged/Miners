#ifndef DCPU16INS_H
#define DCPU16INS_H

// Instructions
typedef enum {
	// Basic instructions
	DI_NonBasic, DI_Set, DI_Add, DI_Sub, DI_Mul, DI_Div, DI_Mod, DI_Shl, 
	DI_Shr, DI_And, DI_Bor, DI_Xor, DI_Ife, DI_Ifn, DI_Ifg, DI_Ifb,

	// Extended instructions
	DI_ExtReserved, DI_ExtJsr,

	// Dtools Extended instructions
	DI_ExtSys
} DIns;

#define DINS_NUM (DI_ExtSys + 1)
#define DINS_NUM_BASIC (DI_Ifb + 1)
#define DINS_EXT_BASE (DI_ExtReserved)

#define DINSNAMES {"NONBASIC", "SET", "ADD", "SUB", "MUL", "DIV", "MOD", "SHL", "SHR", \
	"AND", "BOR", "XOR", "IFE", "IFN", "IFG", "IFB", "RESERVED_EXTENDED", "JSR", "SYS"}

// Value encoding
typedef enum {
	DV_A, DV_B, DV_C, DV_X, DV_Y, DV_Z, DV_I, DV_J,
	DV_RefBase = 0x08, DV_RefTop = 0x0f,
	DV_RefRegNextWordBase = 0x10, DV_RefRegNextWordTop = 0x17,
	DV_Pop, DV_Peek, DV_Push,
	DV_SP, DV_PC,
	DV_O,
	DV_RefNextWord, DV_NextWord,
	DV_LiteralBase,
	DV_LiteralTop = 0x3f
} DVals;

#define VALNAMES {\
	"A", "B", "C", "X", "Y", "Z", "I", "J",\
	"[A]", "[B]", "[C]", "[X]", "[Y]", "[Z]", "[I]", "[J]",\
	"[NW+A]", "[NW+B]", "[NW+C]", "[NW+X]", "[NW+Y]", "[NW+Z]", "[NW+I]", "[NW+J]",\
	"[SP++]", "[SP]", "[--SP]",\
	"SP", "PC",\
	"O",\
	"[NW]", "NW",\
	"0x00", "0x01", "0x02", "0x03", "0x04", "0x05", "0x06", "0x07",\
	"0x08", "0x09", "0x0A", "0x0B", "0x0C", "0x0D", "0x0E", "0x0F",\
	"0x10", "0x11", "0x12", "0x13", "0x14", "0x15", "0x16", "0x17",\
	"0x18", "0x19", "0x1A", "0x1B", "0x1C", "0x1D", "0x1E", "0x1F",\
}

#endif
