#include <stdio.h>
#include "Vperi_pwm_channel.h"
#include "sim/vsim.h"
#include "sim/rand.h"
#include "sim/wishbone.h"

#define CLK_SYS_PERIOD 30
#define CLK_SYS_PHASE 3

int
main(int argc, char **argv)
{
	wishbone_data_t data = 0;
	wishbone_data_t expected_pwm;
	uint64_t state = 0;

	vsim_init(argc, argv);

	for (nanosecond_t ns = 100; ns < 1000000; ns++) {
		if (POSEDGE(ns, CLK_SYS_PERIOD, CLK_SYS_PHASE)) {
			vsim_posedge();
			wishbone_peri_posedge(&data);

			switch (state++) {
			case 1:
				vsim->rst_ni = 1;
				state = 10000;
				break;
			case 10000:
				expected_pwm = rand_byte();
				wishbone_peri_queue_write(0x0000, expected_pwm);
				state -= rand_u64(2000, 3000);
				break;
			}
		}
		if (NEGEDGE(ns, CLK_SYS_PERIOD, CLK_SYS_PHASE)) {
			vsim_negedge();
		}
		vsim_apply(ns);
	}
	vsim_finish();
	return 0;
}
