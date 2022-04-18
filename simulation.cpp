#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <arpa/inet.h>
#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vsimulation.h"

static uint64_t tick_count;
static uint64_t tick_max = 10000;
VerilatedVcdC *tick_vcd;

static void
put(char const *var, uint64_t u64, uint8_t size)
{
	printf(" %s:", var);
	for (u64 <<= 64 - size; size > 0; size--, u64 <<= 1)
		putchar(u64 & (1ull << 63) ? '1' : '0');
}

static void
tick(Vsimulation *v)
{
	if (++tick_count > tick_max) {
		fprintf(stderr, "warning: max tick count reached, exiting\n");
		exit(0);
	}

	v->eval();
	tick_vcd->dump(tick_count * 10 - 1);

	v->wb_clk_i = 1;

	v->eval();
	tick_vcd->dump(tick_count * 10);

	v->wb_clk_i = 0;

	v->eval();
	tick_vcd->dump(tick_count * 10 + 5);

	tick_vcd->flush();
}

/*
 * Wishbone B4 read request in pipelined mode
 */
static inline uint32_t
wb_read(Vsimulation *v, uint32_t addr)
{
	v->wb_cyc_i = 1;
	v->wb_stb_i = 1;
	v->wb_we_i = 0;
	v->wb_adr_i = addr;
	tick(v);

	while (v->wb_stall_o) tick(v);
	v->wb_stb_i = 0;
	v->wb_we_i = 0;
	while (!v->wb_ack_o) tick(v);
	v->wb_cyc_i = 0;

	return 0; //v->wb_dat_o;
}

/*
 * Wishbone B4 write request in pipeline mode
 */
static inline void
wb_write(Vsimulation *v, uint32_t addr, uint32_t data)
{
	v->wb_cyc_i = 1;
	v->wb_stb_i = 1;
	v->wb_we_i = 1;
	v->wb_adr_i = addr;
	v->wb_dat_i = data;
	tick(v);

	while (v->wb_stall_o) tick(v);
	v->wb_stb_i = 0;
	v->wb_we_i = 0;
	while (!v->wb_ack_o) tick(v);
	v->wb_cyc_i = 0;
}

Vsimulation *
init(int argc, char **argv)
{
	Vsimulation *v;

	Verilated::commandArgs(argc, argv);
	Verilated::traceEverOn(true);

	v = new Vsimulation;
	tick_vcd = new VerilatedVcdC;

	v->trace(tick_vcd, 99);
	tick_vcd->open("simulation.vcd");

	v->wb_rst_i = 1;
	tick(v);
	v->wb_rst_i = 0;

	return v;
}

int
main(int argc, char **argv)
{
	Vsimulation *v = init(argc, argv);

	wb_write(v, 0, 0x5);  // red
	wb_write(v, 1, 0x6);  // green
	wb_write(v, 2, 0x7);  // blue
	for (size_t i = 0; i < 0x200; i++)
		tick(v);
}
