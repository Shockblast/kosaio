# sdl3-custom-32.mk - SDL3 kosaio custom (host-32)
# Source: kosaio sdl3-32.tool, installed to /opt/kosaio/data/lib/sdl3/32/

SDL3_CUSTOM-32_CFLAGS  := -I/opt/kosaio/data/include/SDL3
SDL3_CUSTOM-32_LDFLAGS := -L/opt/kosaio/data/lib/sdl3/32 -Wl,-rpath,/opt/kosaio/data/lib/sdl3/32 -lSDL3 -lSDL3main
