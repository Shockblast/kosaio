# openal-32.mk - OpenAL apt (host-32)
# Source: apt libopenal-dev:i386 (multi-arch /usr/lib/i386-linux-gnu)

OPENAL-32_CFLAGS  := -I/usr/include/AL
OPENAL-32_LDFLAGS := -L/usr/lib/i386-linux-gnu -lopenal
