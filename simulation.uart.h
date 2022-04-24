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
};

static inline void
uart_init(struct uart *u, Vsimulation *v)
{
	memset(u, 0, sizeof *u);
	/* coming from the verilog */
	u->v = v;
}

static void
uart_tick_tx(struct uart *u)
{
	if (u->tx.state == UART_TX_IDLE) {
		/* if idle, wait that the library user submit data to send */
		if (u->tx.shift_register_full) {
			u->tx.ticks_counter = 0;
			u->tx.state++;
		}
	} else {
		/* increment with wrap-around */
		if (++u->tx.ticks_counter == u->v->uart_ticks_per_baud)
			u->tx.ticks_counter = 0;
	}

	if (u->tx.ticks_counter == 0) {
		switch (u->tx.state++) {
		case UART_TX_IDLE:
			break;
		case UART_TX_START:
			u->v->uart_rx = 0;
			break;
		case UART_TX_BIT_0:
		case UART_TX_BIT_1:
		case UART_TX_BIT_2:
		case UART_TX_BIT_3:
		case UART_TX_BIT_4:
		case UART_TX_BIT_5:
		case UART_TX_BIT_6:
		case UART_TX_BIT_7:
			u->v->uart_rx = !(u->tx.shift_register & 1);
			u->tx.shift_register >>= 1;
			break;
		case UART_TX_STOP:
			u->tx.state = 0;
			u->tx.shift_register_full = 0;
			u->v->uart_rx = 1;
			break;
		default:
			assert(!"unreached");
		}
	}
}

static int
uart_tick_rx(struct uart *u)
{
	int sampling = 0;

	if (u->rx.state == UART_RX_IDLE) {
		/* if idle, wait that data comes out of the peer's TX */
		if (u->v->uart_tx == 0) {
			u->rx.ticks_counter = 0;
			u->rx.state++;
		}
	} else {
		/* increment with wrap-around */
		if (++u->rx.ticks_counter == u->v->uart_ticks_per_baud)
			u->rx.ticks_counter = 0;
	}

	if (u->rx.ticks_counter == u->v->uart_ticks_per_baud / 2) {
		switch (u->rx.state++) {
		case UART_RX_IDLE:
		case UART_RX_START:
			break;
		case UART_RX_BIT_0:
		case UART_RX_BIT_1:
		case UART_RX_BIT_2:
		case UART_RX_BIT_3:
		case UART_RX_BIT_4:
		case UART_RX_BIT_5:
		case UART_RX_BIT_6:
		case UART_RX_BIT_7:
			u->rx.shift_register =
			 (u->rx.shift_register >> 1) | (!u->v->uart_tx << 7);
			sampling = 1;
			break;
		case UART_RX_STOP:
			u->rx.state = 0;
			u->rx.shift_register_ready = 1;
			break;
		default:
			assert(!"unreached");
		}
	}
	return sampling;
}

static int
uart_tick(struct uart *u)
{
	uart_tick_tx(u);
	return uart_tick_rx(u);
}

static inline char
uart_rx_byte(struct uart *u)
{
	while (!u->rx.shift_register_ready) {
		simulation_tick_begin(u->v);
		uart_tick(u);
		simulation_tick_end(u->v);
	}
	u->rx.shift_register_ready = 0;
	return u->rx.shift_register;
}

static inline void
uart_tx_byte(struct uart *u, char c)
{
	while (u->tx.shift_register_full) {
		simulation_tick_begin(u->v);
		uart_tick(u);
		simulation_tick_end(u->v);
	}
	u->tx.shift_register = c;
	u->tx.shift_register_full = 1;
}
