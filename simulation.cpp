#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vsimulation.h"

#include "simulation.h"
#include "simulation.spi.h"
#include "simulation.wbm.h"

#define CLK_MAIN_PERIOD 30
#define CLK_MAIN_PHASE 3

#define CLK_SPI_PERIOD 31
#define CLK_SPI_PHASE 0

int
main(int argc, char **argv)
{
	simulation_init(argc, argv);
	simulation_eval(0);

	wbm_queue_write(0x00, 0xF, 0x12345678);

	for (nanosecond_t ns = 100; ns < 1000000; ns++) {

		// main clock domain
		if (ns % CLK_MAIN_PERIOD == CLK_MAIN_PHASE)
			simulation_tick_posedge(ns);
		if (ns % CLK_MAIN_PERIOD ==
		  (CLK_MAIN_PHASE + CLK_MAIN_PERIOD / 2) % CLK_MAIN_PERIOD)
			simulation_tick_negedge(ns);

		// spi clock domain
		if (ns % CLK_SPI_PERIOD == CLK_SPI_PHASE) {
			if (spi.bits == 0) {
				uint8_t state = wbm.state;
				spi.tx = wbm_io(spi.rx);
			}
			spi_tick_posedge(ns);
		}
		if (ns % CLK_SPI_PERIOD ==
		  (CLK_SPI_PHASE + CLK_SPI_PERIOD / 2) % CLK_SPI_PERIOD)
			spi_tick_negedge(ns);
	}

	simulation_finish();
}
