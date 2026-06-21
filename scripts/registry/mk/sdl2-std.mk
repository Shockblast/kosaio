# sdl2-std.mk - SDL2 apt (host-64)
# Source: apt libsdl2-dev:amd64 (multi-arch /usr/lib/x86_64-linux-gnu)
# Provides the full link set returned by sdl2-config on this target.

SDL2_STD_CFLAGS  := -I/usr/include/SDL2 -D_REENTRANT
SDL2_STD_LDFLAGS := -L/usr/lib/x86_64-linux-gnu \
                     -lSDL2 -lSDL2main \
                     -lX11 -lpthread -ldl -lrt -lm
