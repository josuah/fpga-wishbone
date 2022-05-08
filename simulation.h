static uint64_t tick_count;
static uint64_t tick_max = 0x10000;
VerilatedVcdC *tick_vcd;

static void
simulation_put(char const *var, uint64_t u64, uint8_t size)
{
	printf(" %s:", var);
	for (u64 <<= 64 - size; size > 0; size--, u64 <<= 1)
		putchar(u64 & (1ull << 63) ? '1' : '0');
}

static void
simulation_tick_begin(Vsimulation *v)
{
	if (++tick_count > tick_max) {
		fprintf(stderr, "warning: max tick count reached, exiting\n");
		exit(0);
	}

	v->eval();
	tick_vcd->dump(tick_count * 10 - 1);

	v->clk = 1;

	v->eval();
	tick_vcd->dump(tick_count * 10);
}

static void
simulation_tick_end(Vsimulation *v)
{
	v->clk = 0;

	v->eval();
	tick_vcd->dump(tick_count * 10 + 5);

	tick_vcd->flush();
}

static Vsimulation *
simulation_init(int argc, char **argv)
{
	Vsimulation *v;

	Verilated::commandArgs(argc, argv);
	Verilated::traceEverOn(true);

	v = new Vsimulation;
	tick_vcd = new VerilatedVcdC;

	v->trace(tick_vcd, 99);
	tick_vcd->open("simulation.vcd");

	return v;
}