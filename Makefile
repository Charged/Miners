########################################
# Find which compilers are installed.
#
CC ?= gcc
DMD ?= $(shell which dmd)
HOST_UNAME := $(strip $(shell uname))
HOST_MACHINE := $(strip $(shell uname -m))
UNAME ?= $(HOST_UNAME)
MACHINE ?= $(strip $(shell uname -m))

ifeq ($(strip $(DMD)),)
	DMD := $(shell which gdmd)
	ifeq ($(strip $(DMD)),)
		DMD = gdmd
	endif
endif

########################################
# The find which platform rules to use.
#
ifeq ($(HOST_UNAME),Linux)
	OBJ_TYPE := o
else
ifeq ($(HOST_UNAME),Darwin)
	OBJ_TYPE := o
else
	OBJ_TYPE := obj
endif
endif


CFLAGS ?= -g -Wall
DFLAGS ?= -gc -debug
LDFLAGS ?= -gc

DDEFINES = -version=DynamicODE
TARGET = Charge
CCOMP_FLAGS = $(CARCH) -c -o $@ $(CFLAGS)
DCOMP_FLAGS = -c -w -Isrc -Jres/builtins $(DDEFINES) -of$@ $(DFLAGS)
LINK_FLAGS = -quiet -of$(TARGET) $(OBJ) -L-ldl $(LDFLAGS)

ifeq ($(UNAME),Linux)
	PLATFORM=linux
else
ifeq ($(UNAME),Darwin)
	PLATFORM=mac

	# Extra to get the program working correctly
	EXTRA_OBJ = $(OBJ_DIR)/SDLmain.o
	CARCH= -arch i386 -arch x86_64
	LINK_FLAGS = -quiet -of$(TARGET) $(OBJ) -L-ldl -L-framework -LCocoa $(LDFLAGS)
else
ifeq ($(UNAME),WindowsCross)
	PLATFORM=windows
	TARGET = Charge.exe

	# Work around winsocket issue
	LINK_FLAGS = -gc -quiet -of$(TARGET) $(OBJ) -L-lgphobos -L-lws2_32 $(LDFLAGS)
else
	PLATFORM=windows
	TARGET = Charge.exe

	# Change the link flags
	LINK_FLAGS = -quiet -of$(TARGET) $(OBJ) -L-lws2_32 $(LDFLAGS)
endif
endif
endif

OBJ_DIR=.obj/$(PLATFORM)-$(MACHINE)
CSRC = $(shell find src -name "*.c")
COBJ = $(patsubst src/%.c, $(OBJ_DIR)/%.$(OBJ_TYPE), $(CSRC))
DSRC = $(shell find src -name "*.d")
DOBJ = $(patsubst src/%.d, $(OBJ_DIR)/%.$(OBJ_TYPE), $(DSRC))
OBJ := $(COBJ) $(DOBJ) $(EXTRA_OBJ)

all: $(TARGET)

#Special target for MacOSX
$(OBJ_DIR)/SDLmain.o : src/charge/platform/SDLmain.m Makefile
	@echo "  CC     src/charge/platform/SDLmain.m"
	@gcc $(CARCH) -I/Library/Frameworks/SDL.framework/Headers -c -o $@ src/charge/platform/SDLmain.m

$(OBJ_DIR)/%.$(OBJ_TYPE) : src/%.c Makefile
	@echo "  CC     src/$*.c"
	@mkdir -p $(dir $@)
	@$(CC) $(CCOMP_FLAGS) src/$*.c

$(OBJ_DIR)/%.$(OBJ_TYPE) : src/%.d Makefile
	@echo "  DMD    src/$*.d"
	@mkdir -p $(dir $@)
	@$(DMD) $(DCOMP_FLAGS) src/$*.d

$(TARGET): $(OBJ)
	@echo "  LD     $@"
	@$(DMD) $(LINK_FLAGS)

clean:
	@rm -rf $(TARGET) .obj

run: $(TARGET) res
	@./$(TARGET)

debug: $(TARGET)
	@gdb ./$(TARGET)

server: $(TARGET)
	@./$(TARGET) -server

xml: $(TARGET)
	@./$(TARGET) -xmltest

touch: dotouch all

dotouch:
	@find src/robbers -name "*.d" | xargs touch

res:
	@wget -nv -r -l1 --no-parent -nH --cut-dirs=2 -A.jpg -A.ini -A.bin -A.bmp -A.xml -A.wav http://irc.walkyrie.se/charged-miners/res/ -Pres

.PHONY: all clean run debug server xml touch dotouch
