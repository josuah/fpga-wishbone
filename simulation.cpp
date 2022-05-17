#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <arpa/inet.h>
#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vsimulation.h"

#include "simulation.h"
#include "simulation.spi.h"

#define WB_CLK_PERIOD 30
#define WB_CLK_PHASE 3

#define SPI_SCK_PERIOD 30
#define SPI_SCK_PHASE 3

int
main(int argc, char **argv)
{
	struct simulation sim;
	struct spi spi;

	simulation_init(&sim, argc, argv);
	spi_init(&spi, &sim);

	sim.v->spi_csn = 0;

	for (size_t i = 0; i < 0x20000; i++) {
		if (i % WB_CLK_PERIOD == WB_CLK_PHASE)
			simulation_tick_posedge(&sim);

		if (i % SPI_SCK_PERIOD == SPI_SCK_PHASE)
			spi_tick_posedge(&spi);

		if (i % WB_CLK_PERIOD ==
		  (WB_CLK_PHASE + WB_CLK_PERIOD / 2) % WB_CLK_PERIOD)
			simulation_tick_negedge(&sim);

		if (i % SPI_SCK_PERIOD ==
		  (SPI_SCK_PHASE + SPI_SCK_PERIOD / 2) % SPI_SCK_PERIOD)
			spi_tick_negedge(&spi);
	}
}
