# libdreamroq.mk - libdreamroq para KOS (Dreamcast)
# Source: kosaio libdreamroq.tool, installed to KOS_BASE/addons

DREAMROQ_DC_CFLAGS  := -I/opt/toolchains/dc/kos/addons/include
DREAMROQ_DC_LDFLAGS := -L/opt/toolchains/dc/kos/addons/lib/dreamcast -ldreamroq -lm
