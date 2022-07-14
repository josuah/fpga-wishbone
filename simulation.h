#include "verilated_vcd_c.h"

VM *vsim;
VerilatedVcdC *vcd;

int simulation_changed = 0;

typedef uint64_t nanosecond_t;

static void
simulation_fatal(char const *fmt, ...)
{
	va_list va;

	va_start(va, fmt);
	fputs("fatal: ", stderr);
	vfprintf(stderr, fmt, va);
	fputs("\n", stderr);
}

static void
simulation_put(char const *var, uint64_t u64, uint8_t size)
{
	printf(" %s:", var);
	for (u64 <<= 64 - size; size > 0; size--, u64 <<= 1)
		putchar(u64 & (1ull << 63) ? '1' : '0');
}

static void
simulation_eval(void)
{
	vsim->eval();
	simulation_changed = 1;
}

static void
simulation_init(int argc, char **argv)
{
	Verilated::commandArgs(argc, argv);
	Verilated::traceEverOn(true);

	vsim = new VM;
	vcd = new VerilatedVcdC;

	vsim->trace(vcd, 99);
	vcd->open("/dev/stdout");

	vsim->eval();
	vcd->dump(0);
}

static void
simulation_tick_posedge(void)
{
	vsim->clk = 1;
	simulation_eval();
}

static void
simulation_tick_negedge(void)
{
	vsim->clk = 0;
	simulation_eval();
}

static void
simulation_finish(void)
{
	vcd->flush();
}

static void
simulation_tick_apply(uint64_t ns)
{
	if (simulation_changed)
		vcd->dump(ns);
	simulation_changed = 0;
}

static void
simulation_tick_ns(nanosecond_t *ns, nanosecond_t delay)
{
	*ns += delay;
	simulation_tick_posedge();
	simulation_tick_negedge();
	simulation_tick_apply(*ns);
}
