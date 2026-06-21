# sdl2-custom-32.mk - SDL2 kosaio custom (host-32)
# Source: kosaio sdl2-32.tool, installed to /opt/kosaio/data/lib/sdl2/32/
# Headers come from apt (SDL2 API is stable across 2.30/2.33 for typical use)

SDL2_CUSTOM-32_CFLAGS  := -I/usr/include/SDL2 -D_REENTRANT
SDL2_CUSTOM-32_LDFLAGS := -L/opt/kosaio/data/lib/sdl2/32 -Wl,-rpath,/opt/kosaio/data/lib/sdl2/32 -lSDL2 -lSDL2main
