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

char
uart_get_byte(struct uart *uart, struct Vsimulation *v)
{
	while (uart->shift_register_ready == 0)
		tick(v);
	uart->shift_register_ready = 0;
	return uart->shift_register;
}

// on tick:
//	v->i_uart_sampling = uart_tick(&uart, 0);
//	v->i_uart_ticks_cnt = uart.ticks_cnt;

// on init:
//	uart_init(&uart, v->o_uart_setup);
