# sdl2-dc.mk - SDL2 para KOS (Dreamcast)
# Source: kosaio sdl2-dc.tool, installed to KOS_BASE/addons

SDL2_DC_CFLAGS  := -I/opt/toolchains/dc/kos/addons/include -I/opt/toolchains/dc/kos/addons/include/SDL2
SDL2_DC_LDFLAGS := -L/opt/toolchains/dc/kos/addons/lib/dreamcast -lSDL2main -lSDL2 -lpthread -lm -lGL
