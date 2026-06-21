# sdl2-std.mk - SDL2 apt (host-64)
# Source: apt libsdl2-dev:amd64 (multi-arch /usr/lib/x86_64-linux-gnu)

SDL2_STD_CFLAGS  := -I/usr/include/SDL2 -D_REENTRANT
SDL2_STD_LDFLAGS := -L/usr/lib/x86_64-linux-gnu -lSDL2 -lSDL2main
