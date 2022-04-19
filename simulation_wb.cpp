#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <arpa/inet.h>
#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vsimulation.h"

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
