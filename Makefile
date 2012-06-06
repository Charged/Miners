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


# gdmd's -g exports native D debugging info use
# that instead of emulated c ones that -gc gives us.
ifeq ($(notdir $(DMD)),gdmd)
	DEBUG_DFLAGS = -g -debug
else
	DEBUG_DFLAGS = -gc -debug
endif


CFLAGS ?= -g
DFLAGS ?= $(DEBUG_DFLAGS)
LDFLAGS ?= $(DEBUG_DFLAGS)

DDEFINES = $(ODE_DDEFINES) $(SDL_DDEFINES)
LDFLAGS_ = $(ODE_LDFLAGS) $(SDL_LDFLAGS) $(LDFLAGS)
TARGET = Charge
CCOMP_FLAGS = $(CARCH) -c $(CFLAGS) -o $@
MCOMP_FLAGS = $(CARCH) -c $(CFLAGS)
DCOMP_FLAGS = -c -w -Isrc -Jres/builtins -Jres/miners $(DDEFINES) $(DFLAGS)
LINK_FLAGS = -quiet -L-ldl $(LDFLAGS_)

ifneq ($(strip $(USE_SDL)),)
	SDL_LDFLAGS = -L-lSDL
else
	SDL_DDEFINES = -version=DynamicSDL
endif

ifneq ($(strip $(USE_ODE)),)
	ODE_LDFLAGS = -L-L. -L-lode -L-lstdc++
else
	ODE_DDEFINES = -version=DynamicODE
endif

ifeq ($(UNAME),Linux)
	PLATFORM=linux
else
ifeq ($(UNAME),Darwin)
	PLATFORM=mac

	# Extra to get the program working correctly
	MSRC = $(shell find src -name "*.m")
	EXTRA_OBJ = $(patsubst src/%.m, $(OBJ_DIR)/%.$(OBJ_TYPE), $(MSRC))
	CARCH= -arch i386 -arch x86_64
	LINK_FLAGS = -quiet -L-ldl -L-framework -LCocoa $(LDFLAGS_)
else
ifeq ($(UNAME),WindowsCross)
	PLATFORM=windows
	TARGET = Charge.exe

	# Work around winsocket issue
	LINK_FLAGS = -gc -quiet -L-lgphobos -L-lws2_32 $(LDFLAGS_)
else
	PLATFORM=windows
	TARGET = Charge.exe

	CCOMP_FLAGS = $(CARCH) -c $(CFLAGS) -o"$@"
	# Change the link flags
	LINK_FLAGS = -quiet $(LDFLAGS_)
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

$(OBJ_DIR)/%.$(OBJ_TYPE) : src/%.m Makefile
	@echo "  CC     src/$*.m"
	@mkdir -p $(dir $@)
	@$(CC) $(MCOMP_FLAGS) -o $@ src/$*.m

$(OBJ_DIR)/%.$(OBJ_TYPE) : src/%.c Makefile
	@echo "  CC     src/$*.c"
	@mkdir -p $(dir $@)
	@$(CC) $(CCOMP_FLAGS) src/$*.c

$(OBJ_DIR)/%.$(OBJ_TYPE) : src/%.d Makefile
	@echo "  DMD    src/$*.d"
	@mkdir -p $(dir $@)
	@$(DMD) $(DCOMP_FLAGS) -of$@ src/$*.d

$(TARGET): $(OBJ) Makefile
	@echo "  LD     $@"
	@$(DMD) $(LINK_FLAGS) -of$@ $(OBJ)

clean:
	@rm -rf $(TARGET) .obj

run: $(TARGET)
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


.PHONY: all clean run debug server xml touch dotouch


# Special dependancy for minecraft lua inbuilt scripts.
MCLUAFILES = $(shell find res/miners -name "*.lua")
$(OBJ_DIR)/miners/lua/builtin.$(OBJ_TYPE): $(MCLUAFILES)
