#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <arpa/inet.h>
#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vsimulation.h"

#include "simulation.h"
#include "simulation.uart.h"

int
main(int argc, char **argv)
{
	struct Vsimulation *v = simulation_init(argc, argv);
	struct uart u;
	char c;

	uart_init(&u, v);

	v->uart_rx = 1;

	simulation_tick_begin(v);
	simulation_tick_end(v);

	simulation_tick_begin(v);
	simulation_tick_end(v);

	simulation_tick_begin(v);
	simulation_tick_end(v);

	for (size_t i = 0; i < 0x200000; i++) {
		uart_tx_byte(&u, '.');
		c = uart_rx_byte(&u);
	}
}
