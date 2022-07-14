#include "VmUartRx.h"
#include "simulation.h"
#include "simulation.random.h"

int
main(int argc, char **argv)
{
	nanosecond_t ns = 0;

	simulation_init(argc, argv);

	vsim->rst = 1;
	simulation_tick_ns(&ns, 10);

	vsim->rst = 0;
	simulation_tick_ns(&ns, 10);

	simulation_tick_ns(&ns, random_u64(90, 110));

	vsim->rst = 0;

	simulation_finish();
}
