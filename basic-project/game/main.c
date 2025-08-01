#include <kos.h>
#include <kos/dbgio.h>
#include <arch/gdb.h>

int main(int argc, char **argv)
{
	gdb_init();

	// Inicializar KallistiOS
	KOS_INIT_FLAGS(INIT_DEFAULT);
	dbgio_init();
	dbgio_dev_select("fb");

	// Inicializar el juego (nunca retorna)
	while (1)
	{
		dbgio_printf("Hello from Kosaio/Kallistios/Dreamcast");
		dbgio_flush();
	}

	return 0;
}