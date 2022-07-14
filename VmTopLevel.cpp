#include <stdio.h>
#include "VmTopLevel.h"
#include "simulation.h"
#include "simulation.spi.h"
#include "simulation.wbc.h"

#define CLK_MAIN_PERIOD 30
#define CLK_MAIN_PHASE 3

#define CLK_SPI_PERIOD 31
#define CLK_SPI_PHASE 0

int
main(int argc, char **argv)
{
	simulation_init(argc, argv);

	wbc_queue_write(0x00, 0xF, 0x55);

	for (nanosecond_t ns = 100; ns < 10000; ns++) {

		// main clock domain
		if (ns % CLK_MAIN_PERIOD == CLK_MAIN_PHASE)
			simulation_tick_posedge();
		if (ns % CLK_MAIN_PERIOD ==
		  (CLK_MAIN_PHASE + CLK_MAIN_PERIOD / 2) % CLK_MAIN_PERIOD)
			simulation_tick_negedge();

		// spi clock domain
		if (ns % CLK_SPI_PERIOD == CLK_SPI_PHASE) {
			if (spi.bits == 0) {
				uint8_t state = wbc.state;
				spi.tx = wbc_io(spi.rx);
			}
			spi_tick_posedge();
		}
		if (ns % CLK_SPI_PERIOD ==
		  (CLK_SPI_PHASE + CLK_SPI_PERIOD / 2) % CLK_SPI_PERIOD)
			spi_tick_negedge();

		simulation_tick_apply(ns);
	}

	simulation_finish();
}
