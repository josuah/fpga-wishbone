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

enum uart_status {
	UART_STATUS_WAITING_FIRST_EDGE,
	UART_STATUS_WAITING_START,
	UART_STATUS_WAITING_BIT_0,
	UART_STATUS_WAITING_BIT_1,
	UART_STATUS_WAITING_BIT_2,
	UART_STATUS_WAITING_BIT_3,
	UART_STATUS_WAITING_BIT_4,
	UART_STATUS_WAITING_BIT_5,
	UART_STATUS_WAITING_BIT_6,
	UART_STATUS_WAITING_BIT_7,
	UART_STATUS_WAITING_STOP,
};

struct uart {
	uint64_t ticks_per_baud;
	uint64_t ticks_cnt;
	int status;
	uint8_t shift_register;
	int shift_register_ready;
} uart;

void
uart_init(struct uart *uart, uint32_t o_uart_setup)
{
	memset(uart, 0, sizeof *uart);
	/* coming from the verilog */
	uart->ticks_per_baud = o_uart_setup;
}

int
uart_tick(struct uart *uart, uint8_t pin)
{
	int sampling = 0;

	if (uart->status == UART_STATUS_WAITING_FIRST_EDGE) {
		/* is start bit detected? */
		if (pin == 0) {
			uart->ticks_cnt = 0;
			uart->status++;
		}
	} else {
		/* increment with wrap-around */
		if (++uart->ticks_cnt == uart->ticks_per_baud)
			uart->ticks_cnt = 0;
	}

	if (uart->ticks_cnt == uart->ticks_per_baud / 2) {
		switch (uart->status++) {
		case UART_STATUS_WAITING_FIRST_EDGE:
		case UART_STATUS_WAITING_START:
			break;
		case UART_STATUS_WAITING_BIT_0:
		case UART_STATUS_WAITING_BIT_1:
		case UART_STATUS_WAITING_BIT_2:
		case UART_STATUS_WAITING_BIT_3:
		case UART_STATUS_WAITING_BIT_4:
		case UART_STATUS_WAITING_BIT_5:
		case UART_STATUS_WAITING_BIT_6:
		case UART_STATUS_WAITING_BIT_7:
			uart->shift_register =
			 (uart->shift_register >> 1) | (!pin << 7);
			sampling = 1;
			break;
		case UART_STATUS_WAITING_STOP:
			uart->status = 0;
			uart->shift_register_ready = 1;
			break;
		default:
			assert(!"unreached");
		}
	}
	return sampling;
}

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

	v->i_wb_clk = 1;

	v->eval();
	v->i_uart_sampling = uart_tick(&uart, 0);
	v->i_uart_ticks_cnt = uart.ticks_cnt;
	v->eval();
	tick_vcd->dump(tick_count * 10);

	v->i_wb_clk = 0;

	v->eval();
	tick_vcd->dump(tick_count * 10 + 5);

	tick_vcd->flush();
}

static inline uint32_t
wb_read(Vsimulation *v, uint32_t addr)
{
	v->i_wb_cyc = 1;
	v->i_wb_stb = 1;
	v->i_wb_we = 0;
	v->i_wb_addr = addr;
	tick(v);

	while (!v->o_wb_ack) tick(v);
	v->i_wb_stb = 0;
	v->i_wb_cyc = 0;
	v->i_wb_we = 0;

	return v->o_wb_data;
}

static inline void
wb_write(Vsimulation *v, uint32_t addr, uint32_t data)
{
	v->i_wb_cyc = 1;
	v->i_wb_stb = 1;
	v->i_wb_we = 1;
	v->i_wb_addr = addr;
	v->i_wb_data = data;
	tick(v);

	while (!v->o_wb_ack) tick(v);
	v->i_wb_stb = 0;
	v->i_wb_cyc = 0;
	v->i_wb_we = 0;
}

char
uart_get_byte(struct uart *uart, struct Vsimulation *v)
{
	while (uart->shift_register_ready == 0)
		tick(v);
	uart->shift_register_ready = 0;
	return uart->shift_register;
}

void
peek(Vsimulation *v)
{
	uint32_t u32 = wb_read(v, 0);

	fprintf(stderr, "read 0x%02X ('%c')\n", u32, u32);
}

int
main(int argc, char **argv)
{
	Verilated::commandArgs(argc, argv);
	Verilated::traceEverOn(true);
	Vsimulation *v;
	uint8_t c;

	v = new Vsimulation;
	tick_vcd = new VerilatedVcdC;

	v->trace(tick_vcd, 99);
	tick_vcd->open("simulation.vcd");

	tick(v); v->i_wb_rst = 1;
	tick(v); v->i_wb_rst = 0;
	uart_init(&uart, v->o_uart_setup);
	tick(v);

	wb_write(v, 0, 'H'); peek(v);
	wb_write(v, 0, 'e'); peek(v);
	wb_write(v, 0, 'l'); peek(v);
	wb_write(v, 0, 'l'); peek(v);
	wb_write(v, 0, 'o'); peek(v);
	wb_write(v, 0, ' '); peek(v);
	wb_write(v, 0, 'w'); peek(v);
	wb_write(v, 0, 'o'); peek(v);
	wb_write(v, 0, 'r'); peek(v);
	wb_write(v, 0, 'l'); peek(v);
	wb_write(v, 0, 'd'); peek(v);
	wb_write(v, 0, '!'); peek(v);

	for (size_t i = 0; i < 0x200; i++)
		tick(v);
}
