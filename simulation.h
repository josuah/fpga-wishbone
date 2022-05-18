Vsimulation *vsim;
VerilatedVcdC *vcd;

typedef uint64_t nanosecond_t;

static void
simulation_put(char const *var, uint64_t u64, uint8_t size)
{
	printf(" %s:", var);
	for (u64 <<= 64 - size; size > 0; size--, u64 <<= 1)
		putchar(u64 & (1ull << 63) ? '1' : '0');
}

static void
simulation_eval(nanosecond_t ns)
{
	vsim->eval();
	vcd->dump(ns);
}

static void
simulation_init(int argc, char **argv)
{
	Verilated::commandArgs(argc, argv);
	Verilated::traceEverOn(true);

	vsim = new Vsimulation;
	vcd = new VerilatedVcdC;

	vsim->trace(vcd, 99);
	vcd->open("simulation.vcd");

	simulation_eval(0);
}

static void
simulation_tick_posedge(nanosecond_t ns)
{
	vsim->clk = 1;
	simulation_eval(ns);
}

static void
simulation_tick_negedge(nanosecond_t ns)
{
	vsim->clk = 0;
	simulation_eval(ns);
}

static void
simulation_finish(void)
{
	vcd->flush();
}
