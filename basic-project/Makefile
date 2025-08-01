# KOS RULES AND TOOLS BELLOW DEFINITIONS
include $(KOS_BASE)/Makefile.rules

# When make is invoked by "make VERBOSE=1" print
# the compiler and linker commands.
ifdef VERBOSE
Q :=
else
Q := @
endif

# Files to compile
GAME_OBJS_ = game/main.o

# Rewrite paths to our object directory.
GAME_OBJS = $(patsubst %,build/%,$(GAME_OBJS_))

# Generate header dependencies.
ALL_DEPS= $(ALL_OBJS:.o=.d)

# Suck header dependencies in.
-include $(ALL_DEPS)

# Default action for make
.PHONY: make.dirs build.elf

# Build all
all: build.elf

# Make folders
make.dirs:
	${Q}mkdir -p release
	${Q}mkdir -p build

# Cleanup
clean.builds:
	${Q}echo "===> CLEAN BUILDS"
	${Q}rm -Rf build

clean.releases:
	${Q}echo "===> CLEAN RELEASES"
	${Q}rm -Rf release

clean.all: clean.builds clean.releases make.dirs

# Build
build.elf: $(GAME_OBJS) mdirs
	${Q}echo "===> Building game.elf"
	${Q}rm -f release/game.elf
	${Q}$(KOS_CC) $(KOS_LDFLAGS) -o release/game.elf $(GAME_OBJS) $(KOS_LIBS)

build/%.o: %.c
	${Q}echo "===> KOS-CC $< → $@"
	${Q}mkdir -p $(@D)
	${Q}$(KOS_CC) -c $(KOS_CFLAGS) $(KOS_INC_PATHS) -o $@ $<
