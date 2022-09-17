#include <assert.h>
#include <stdarg.h>
#include "verilated_vcd_c.h"

typedef uint64_t nanosecond_t;

VM *vsim;
VerilatedVcdC *vcd;

int vsim_changed = 0;

#define POSEDGE(ns, period, phase) \
	((ns) % (period) == (phase))

#define NEGEDGE(ns, period, phase) \
	((ns) % (period) == ((phase) + (period)) / 2 % (period))

static void
vsim_fatal(char const *fmt, ...)
{
	va_list va;

	va_start(va, fmt);
	fputs("fatal: ", stderr);
	vfprintf(stderr, fmt, va);
	fputs("\n", stderr);
}

#ifdef NDEBUG
#define debug(...) 0
#else

static void
debug(char const *fmt, ...)
{
	va_list va;

	va_start(va, fmt);
	vfprintf(stderr, fmt, va);
	fputs("\n", stderr);
}
#endif

static void
vsim_put(char const *var, uint64_t u64, uint8_t size)
{
	printf(" %s:", var);
	for (u64 <<= 64 - size; size > 0; size--, u64 <<= 1)
		putchar(u64 & (1ull << 63) ? '1' : '0');
}

static void
vsim_eval(void)
{
	vsim->eval();
	vsim_changed = 1;
}

static void
vsim_init(int argc, char **argv)
{
	Verilated::commandArgs(argc, argv);
	Verilated::traceEverOn(true);

	vsim = new VM;
	vcd = new VerilatedVcdC;

	vsim->trace(vcd, 99);
	vcd->open("/dev/stdout");

	vsim->rst_ni = 0;
	vsim->eval();
	vcd->dump(0);
}

static void
vsim_finish(void)
{
	vcd->flush();
}

static void
vsim_posedge(void)
{
	vsim->clk_i = 1;
	vsim_eval();
}

static void
vsim_negedge(void)
{
	vsim->clk_i = 0;
	vsim_eval();
}

static void
vsim_apply(nanosecond_t ns)
{
	if (vsim_changed)
		vcd->dump(ns);
	vsim_changed = 0;
}
