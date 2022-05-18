#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vsimulation.h"

#include "simulation.h"
#include "simulation.spi.h"

#define CLK_MAIN_PERIOD 30
#define CLK_MAIN_PHASE 3

#define CLK_SPI_PERIOD 11
#define CLK_SPI_PHASE 0

int
main(int argc, char **argv)
{
	char buf[32] = {0};

	simulation_init(argc, argv);

	vsim->spi_csn = 0;

	for (nanosecond_t ns = 0; ns < 20000; ns++) {
		// main clock domain
		if (ns % CLK_MAIN_PERIOD == CLK_MAIN_PHASE)
			simulation_tick_posedge(ns);
		if (ns % CLK_MAIN_PERIOD ==
		  (CLK_MAIN_PHASE + CLK_MAIN_PERIOD / 2) % CLK_MAIN_PERIOD)
			simulation_tick_negedge(ns);

		// spi clock domain
		if (ns % CLK_SPI_PERIOD == CLK_SPI_PHASE) {
			spi_queue_read(buf, sizeof buf);
			spi_queue_write("0123", 4);
			spi_tick_posedge(ns);
		}
		if (ns % CLK_SPI_PERIOD ==
		  (CLK_SPI_PHASE + CLK_SPI_PERIOD / 2) % CLK_SPI_PERIOD)
			spi_tick_negedge(ns);
	}
	simulation_finish();
}
