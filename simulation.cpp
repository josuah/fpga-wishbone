#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <arpa/inet.h>
#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vsimulation.h"

#include "simulation.h"

int
main(int argc, char **argv)
{
	struct Vsimulation *v = simulation_init(argc, argv);

	for (size_t i = 0; i < 0x200000; i++) {
		simulation_tick_begin(v);
		simulation_tick_end(v);
	}
}
