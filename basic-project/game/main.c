#include <kos.h>
#include <dc/video.h>
#include <dc/biosfont.h>
#include <dc/minifont.h>
#include <string.h>

#define SCREEN_W 640
#define SCREEN_H 480
#define FONT_W 8
#define FONT_H 16

/* Dibuja un string centrado horizontalmente en la fila de píxeles 'y'. */
static void draw_str_centered_x(int y, const char *str)
{
	int text_w = (int)strlen(str) * FONT_W;
	int x = (SCREEN_W - text_w) / 2;

	if (x < 0)
		x = 0;

	minifont_draw_str(vram_s + y * SCREEN_W + x, SCREEN_W, str);
}

int main(int argc, char **argv)
{
	// Initialize KallistiOS
	KOS_INIT_FLAGS(INIT_DEFAULT);

	// Initialize video system (640x480, RGB565)
	// This sets up vram_s to point to the framebuffer in VRAM
	vid_init(DM_640x480, PM_RGB565);

	// Clear the framebuffer (optional, ensures clean start)
	memset((void *)vram_s, 0, SCREEN_W * SCREEN_H * 2);

	// Color del texto (blanco por defecto, cámbialo si quieres)
	minifont_set_color(255, 255, 255);

	// Texto centrado horizontal y verticalmente.
	// La fórmula es: x = (ancho_pantalla - ancho_texto) / 2
	// donde ancho_texto = strlen(texto) * 8px (cada glifo minifont mide 8x16).
	// Al pasar el puntero ya desplazado (vram_s + y * 640 + x),
	// minifont_draw_str dibuja justo en el centro.
	draw_str_centered_x(SCREEN_H / 2 - FONT_H / 2,
		"Hello from Kosaio/Kallistios/Dreamcast (bfont)");

	// Main loop - keep display active
	while (1)
	{
		// Wait for VBlank to avoid tearing
		vid_waitvbl();
	}

	return 0;
}
