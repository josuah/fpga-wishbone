#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vsimulation.h"

#include "simulation.h"
#include "simulation.spi.h"

#define CLK_MAIN_PERIOD 30
#define CLK_MAIN_PHASE 3

#define CLK_SPI_PERIOD 31
#define CLK_SPI_PHASE 0

int
main(int argc, char **argv)
{
	uint8_t rx[32] = {0};
	uint8_t tx[] = { 0x8F, 0x00, 0xAA, 0xAA, 0xAA, 0xAA };

	simulation_init(argc, argv);
	vsim->spi_csn = 1;
	simulation_eval(0);

	spi_queue_read(rx, sizeof rx);
	spi_queue_write(tx, 4);

	for (nanosecond_t ns = 100; ns < 50000; ns++) {
		// main clock domain
		if (ns % CLK_MAIN_PERIOD == CLK_MAIN_PHASE)
			simulation_tick_posedge(ns);
		if (ns % CLK_MAIN_PERIOD ==
		  (CLK_MAIN_PHASE + CLK_MAIN_PERIOD / 2) % CLK_MAIN_PERIOD)
			simulation_tick_negedge(ns);

		// spi clock domain
		if (ns % CLK_SPI_PERIOD == CLK_SPI_PHASE) {
			vsim->spi_csn = 0;
			spi_queue_read(rx, sizeof rx);
			spi_queue_write(tx, 4);
			spi_tick_posedge(ns);
		}
		if (ns % CLK_SPI_PERIOD ==
		  (CLK_SPI_PHASE + CLK_SPI_PERIOD / 2) % CLK_SPI_PERIOD)
			spi_tick_negedge(ns);
	}
	simulation_finish();
}
