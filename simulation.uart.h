enum {
	UART_RX_IDLE,
	UART_RX_START,
	UART_RX_BIT_0,
	UART_RX_BIT_1,
	UART_RX_BIT_2,
	UART_RX_BIT_3,
	UART_RX_BIT_4,
	UART_RX_BIT_5,
	UART_RX_BIT_6,
	UART_RX_BIT_7,
	UART_RX_STOP,
};

enum {
	UART_TX_IDLE,
	UART_TX_START,
	UART_TX_BIT_0,
	UART_TX_BIT_1,
	UART_TX_BIT_2,
	UART_TX_BIT_3,
	UART_TX_BIT_4,
	UART_TX_BIT_5,
	UART_TX_BIT_6,
	UART_TX_BIT_7,
	UART_TX_STOP,
};

struct uart_rx {
	uint32_t ticks_counter;
	int state;
	uint8_t shift_register;
	int shift_register_ready;
};

struct uart_tx {
	uint32_t ticks_counter;
	int state;
	uint8_t shift_register;
	int shift_register_full;
};

struct uart {
	Vsimulation *v;
	struct uart_rx rx;
	struct uart_tx tx;
} uart;

static void
uart_tick_tx(void)
{
	if (uart.tx.state == UART_TX_IDLE) {
		/* if idle, wait that the library user submit data to send */
		if (uart.tx.shift_register_full) {
			uart.tx.ticks_counter = 0;
			uart.tx.state++;
		}
	} else {
		/* increment with wrap-around */
		if (++uart.tx.ticks_counter == vsim->uart_ticks_per_baud)
			uart.tx.ticks_counter = 0;
	}

	if (uart.tx.ticks_counter == 0) {
		switch (uart.tx.state) {
		case UART_TX_IDLE:
			break;
		case UART_TX_START:
			vsim->uart_rx = 0;
			uart.tx.state++;
			break;
		case UART_TX_BIT_0:
		case UART_TX_BIT_1:
		case UART_TX_BIT_2:
		case UART_TX_BIT_3:
		case UART_TX_BIT_4:
		case UART_TX_BIT_5:
		case UART_TX_BIT_6:
		case UART_TX_BIT_7:
			vsim->uart_rx = !(uart.tx.shift_register & 1);
			uart.tx.shift_register >>= 1;
			uart.tx.state++;
			break;
		case UART_TX_STOP:
			uart.tx.shift_register_full = 0;
			vsim->uart_rx = 1;
			uart.tx.state = 0;
			break;
		default:
			assert(!"unreached");
		}
	}
}

static int
uart_tick_rx(void)
{
	int sampling = 0;

	if (uart.rx.state == UART_RX_IDLE) {
		/* if idle, wait that data comes out of the peer's TX */
		if (vsim->uart_tx == 0) {
			uart.rx.ticks_counter = 0;
			uart.rx.state++;
		}
	} else {
		/* increment with wrap-around */
		if (++uart.rx.ticks_counter == vsim->uart_ticks_per_baud)
			uart.rx.ticks_counter = 0;
	}

	if (uart.rx.ticks_counter == vsim->uart_ticks_per_baud / 2) {
		switch (uart.rx.state) {
		case UART_RX_IDLE:
			break;
		case UART_RX_START:
			uart.rx.state++;
			break;
		case UART_RX_BIT_0:
		case UART_RX_BIT_1:
		case UART_RX_BIT_2:
		case UART_RX_BIT_3:
		case UART_RX_BIT_4:
		case UART_RX_BIT_5:
		case UART_RX_BIT_6:
		case UART_RX_BIT_7:
			uart.rx.shift_register =
			 (uart.rx.shift_register >> 1) | (!vsim->uart_tx << 7);
			sampling = 1;
			uart.rx.state++;
			break;
		case UART_RX_STOP:
			uart.rx.shift_register_ready = 1;
			uart.rx.state = 0;
			break;
		default:
			assert(!"unreached");
		}
	}
	return sampling;
}

static int
uart_tick(void)
{
	uart_tick_tx(uart);
	return uart_tick_rx(uart);
}

static inline char
uart_rx_byte(void)
{
	while (!uart.rx.shift_register_ready) {
		simulation_tick_begin(vsim);
		uart_tick(uart);
		simulation_tick_end(vsim);
	}
	uart.rx.shift_register_ready = 0;
	return uart.rx.shift_register;
}

static inline void
uart_tx_byte(char c)
{
	while (uart.tx.shift_register_full) {
		simulation_tick_begin(vsim);
		uart_tick(uart);
		simulation_tick_end(vsim);
	}
	uart.tx.shift_register = c;
	uart.tx.shift_register_full = 1;
}
