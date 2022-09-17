#include <stdio.h>
#include "Vtop.h"
#include "sim/vsim.h"
#include "sim/uart.h"

#define CLK_SYS_PERIOD 30
#define CLK_SYS_PHASE 3

#define CLK_UART_PERIOD 31
#define CLK_UART_PHASE 0

int
main(int argc, char **argv)
{
	vsim_init(argc, argv);

	for (nanosecond_t ns = 100; ns < 10000; ns++) {
		if (POSEDGE(ns, CLK_SYS_PERIOD, CLK_SYS_PHASE)) {
			vsim_posedge();
		}
		if (NEGEDGE(ns, CLK_SYS_PERIOD, CLK_SYS_PHASE)) {
			vsim_negedge();
		}
		if (POSEDGE(ns, CLK_UART_PERIOD, CLK_UART_PHASE)) {
			uart_posedge(16);
		}
		vsim_apply(ns);
	}
	vsim_finish();
	return 0;
}
