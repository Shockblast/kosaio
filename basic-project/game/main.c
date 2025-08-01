#include <kos.h>
#include <kos/dbgio.h>

int main(int argc, char **argv)
{
	// Initialize KallistiOS
	KOS_INIT_FLAGS(INIT_DEFAULT);

	// Initialize to show something
	dbgio_init();
	dbgio_dev_select("fb");
	dbgio_printf("Hello from Kosaio/Kallistios/Dreamcast");

	while (1)
	{
		dbgio_flush();
	}

	return 0;
}
