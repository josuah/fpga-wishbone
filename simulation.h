struct simulation {
	uint64_t tick_count;
	uint64_t tick_max;

	Vsimulation *v;
	VerilatedVcdC *vcd;
};


static void
simulation_put(char const *var, uint64_t u64, uint8_t size)
{
	printf(" %s:", var);
	for (u64 <<= 64 - size; size > 0; size--, u64 <<= 1)
		putchar(u64 & (1ull << 63) ? '1' : '0');
}

static void
simulation_eval(struct simulation *sim, uint64_t ns)
{
	sim->v->eval();
	sim->vcd->dump(ns);
}

static void
simulation_tick_posedge(struct simulation *sim, uint64_t ns)
{
	sim->v->clk = 1;
	simulation_eval(sim, ns);
}

static void
simulation_tick_negedge(struct simulation *sim, uint64_t ns)
{
	sim->v->clk = 0;
	simulation_eval(sim, ns);
	sim->vcd->flush();
}

static void
simulation_init(struct simulation *sim, int argc, char **argv)
{
	Verilated::commandArgs(argc, argv);
	Verilated::traceEverOn(true);

	sim->v = new Vsimulation;
	sim->vcd = new VerilatedVcdC;

	sim->v->trace(sim->vcd, 99);
	sim->vcd->open("simulation.vcd");

	sim->tick_max = 0x10000;
}
