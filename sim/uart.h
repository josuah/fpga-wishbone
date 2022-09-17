enum uart_rx_state {
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

enum uart_tx_state {
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
	enum uart_rx_state state;
	uint8_t shift_register;
	int shift_register_ready;
};

struct uart_tx {
	uint32_t ticks_counter;
	enum uart_tx_state state;
	uint8_t shift_register;
	int shift_register_full;
};

static inline struct uart_rx uart_rx;
static inline struct uart_tx uart_tx;

static inline void
uart_tx_posedge(uint32_t ticks_per_baud)
{
	if (uart_tx.state == UART_TX_IDLE) {
		/* if idle, wait that the library user submit data to send */
		if (uart_tx.shift_register_full) {
			uart_tx.ticks_counter = 0;
			uart_tx.state = UART_TX_START;
		}
	} else {
		/* increment with wrap-around */
		if (++uart_tx.ticks_counter == ticks_per_baud)
			uart_tx.ticks_counter = 0;
	}

	if (uart_tx.ticks_counter == 0) {
		switch (uart_tx.state) {
		case UART_TX_IDLE:
			break;
		case UART_TX_START:
			vsim->uart_rx_ni = 0;
			uart_tx.state = UART_TX_BIT_0;
			break;
		case UART_TX_BIT_0:
		case UART_TX_BIT_1:
		case UART_TX_BIT_2:
		case UART_TX_BIT_3:
		case UART_TX_BIT_4:
		case UART_TX_BIT_5:
		case UART_TX_BIT_6:
		case UART_TX_BIT_7:
			vsim->uart_rx_ni = !(uart_tx.shift_register & 1);
			uart_tx.shift_register >>= 1;
			uart_tx.state = (enum uart_tx_state)((int)uart_tx.state + 1);
			break;
		case UART_TX_STOP:
			uart_tx.shift_register_full = 0;
			vsim->uart_rx_ni = 1;
			uart_tx.state = UART_TX_IDLE;
			break;
		default:
			assert(!"unreached");
		}
	}
}

static inline int
uart_rx_posedge(uint32_t ticks_per_baud)
{
	int sampling = 0;

	if (uart_rx.state == UART_RX_IDLE) {
		/* if idle, wait that data comes out of the peer's TX */
		if (vsim->uart_tx_no == 0) {
			uart_rx.ticks_counter = 0;
			uart_rx.state = UART_RX_START;
		}
	} else {
		/* increment with wrap-around */
		if (++uart_rx.ticks_counter == ticks_per_baud)
			uart_rx.ticks_counter = 0;
	}

	if (uart_rx.ticks_counter == ticks_per_baud / 2) {
		switch (uart_rx.state) {
		case UART_RX_IDLE:
			break;
		case UART_RX_START:
			uart_rx.state = UART_RX_BIT_0;
			break;
		case UART_RX_BIT_0:
		case UART_RX_BIT_1:
		case UART_RX_BIT_2:
		case UART_RX_BIT_3:
		case UART_RX_BIT_4:
		case UART_RX_BIT_5:
		case UART_RX_BIT_6:
		case UART_RX_BIT_7:
			uart_rx.shift_register =
			 (uart_rx.shift_register >> 1) | (!vsim->uart_tx_no << 7);
			sampling = 1;
			uart_rx.state = (enum uart_rx_state)((int)uart_rx.state + 1);
			break;
		case UART_RX_STOP:
			uart_rx.shift_register_ready = 1;
			uart_rx.state = UART_RX_IDLE;
			break;
		default:
			assert(!"unreached");
		}
	}
	return sampling;
}

/*
 * To call on each posedge of the UART wire clock: on every baud.
 */
static int
uart_posedge(uint32_t ticks_per_baud)
{
	uart_tx_posedge(ticks_per_baud);
	vsim_eval();
	return uart_rx_posedge(ticks_per_baud);
}

/*
 * Return 0 if data not available.
 * Return 1 when a new byte is received into *byte.
 */
static int
uart_rx_byte(uint8_t *byte)
{
	if (!uart_rx.shift_register_ready)
		return 0;
	*byte = uart_rx.shift_register;
	uart_rx.shift_register_ready = 0;
	return 1;
}

/*
 * Return 0 if not ready yet.
 * Return 1 if the byte could be sent.
 */
static int
uart_tx_byte(uint8_t byte)
{
	if (uart_tx.shift_register_full)
		return 0;
	uart_tx.shift_register = byte;
	uart_tx.shift_register_full = 1;
	return 1;
}
