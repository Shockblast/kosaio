# sdl3-custom-64.mk - SDL3 kosaio custom (host-64)
# Source: kosaio sdl3.tool, installed to /opt/kosaio/data/lib/sdl3/64/

SDL3_CUSTOM-64_CFLAGS  := -I/opt/kosaio/data/include/SDL3
SDL3_CUSTOM-64_LDFLAGS := -L/opt/kosaio/data/lib/sdl3/64 -Wl,-rpath,/opt/kosaio/data/lib/sdl3/64 -lSDL3 -lSDL3main
