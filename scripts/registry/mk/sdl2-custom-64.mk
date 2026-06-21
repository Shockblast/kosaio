# sdl2-custom-64.mk - SDL2 kosaio custom (host-64)
# Source: kosaio sdl2.tool, installed to /opt/kosaio/data/lib/sdl2/64/
# Headers come from apt

SDL2_CUSTOM-64_CFLAGS  := -I/usr/include/SDL2 -D_REENTRANT
SDL2_CUSTOM-64_LDFLAGS := -L/opt/kosaio/data/lib/sdl2/64 -Wl,-rpath,/opt/kosaio/data/lib/sdl2/64 -lSDL2 -lSDL2main
