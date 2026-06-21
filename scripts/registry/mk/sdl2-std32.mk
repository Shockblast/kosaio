# sdl2-std32.mk - SDL2 apt (host-32)
# Source: apt libsdl2-dev:i386 (multi-arch /usr/lib/i386-linux-gnu)

SDL2_STD32_CFLAGS  := -I/usr/include/SDL2 -D_REENTRANT
SDL2_STD32_LDFLAGS := -L/usr/lib/i386-linux-gnu -lSDL2 -lSDL2main
