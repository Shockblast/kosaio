# sdl3-dc.mk - SDL3 para KOS (Dreamcast)
# Source: kosaio sdl3-dc.tool, installed to KOS_BASE/addons

SDL3_DC_CFLAGS  := -I/opt/toolchains/dc/kos/addons/include -I/opt/toolchains/dc/kos/addons/include/SDL3
SDL3_DC_LDFLAGS := -L/opt/toolchains/dc/kos/addons/lib/dreamcast -lSDL3main -lSDL3 -lpthread -lm -lGL
