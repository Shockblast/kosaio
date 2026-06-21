# sdl2-std32.mk - SDL2 apt (host-32)
# Source: apt libsdl2-dev:i386 (multi-arch /usr/lib/i386-linux-gnu)
# Provides the full link set returned by sdl2-config on this target.

SDL2_STD32_CFLAGS  := -I/usr/include/SDL2 -D_REENTRANT
SDL2_STD32_LDFLAGS := -L/usr/lib/i386-linux-gnu \
                       -lSDL2 -lSDL2main \
                       -lX11 -lpthread -ldl -lrt -lm
