// Make request for Wishbone B4 pipelined master over SPI

enum wbm_read_state {
	WBM_READ_STATE_COMMAND,
	WBM_READ_STATE_ADDRESS,
	WBM_READ_STATE_DATA_0,
	WBM_READ_STATE_DATA_1,
	WBM_READ_STATE_DATA_2,
	WBM_READ_STATE_DATA_3,
	WBM_READ_STATE_WAIT_ACK,
};

enum wbm_write_state {
	WBM_WRITE_STATE_COMMAND,
	WBM_WRITE_STATE_ADDRESS,
	WBM_WRITE_STATE_DATA_0,
	WBM_WRITE_STATE_DATA_1,
	WBM_WRITE_STATE_DATA_2,
	WBM_WRITE_STATE_DATA_3,
	WBM_WRITE_STATE_WAIT_ACK,
};

struct wbm_read {
	enum wbm_read_state state;
};

struct wbm_write {
	enum wbm_write_state state;
};

struct wbm {
	struct wbm_read read;
	struct wbm_write write;
} wbm;

void
wbm_queue_read()
{

}

void
wbm_queue_write()
{

}

void
wbm_io(uint16_t addr, uint32_t data)
{
	switch (wbm.write_state) {
	case WBM_WRITE_STATE_COMMAND:
		state = WBM_WRITE_STATE_ADDRESS;
		break;
	case WBM_WRITE_STATE_ADDRESS:
		state = WBM_WRITE_STATE_DATA_0;
		break;
	case WBM_WRITE_STATE_DATA_0:
		state = WBM_WRITE_STATE_DATA_1;
		break;
	case WBM_WRITE_STATE_DATA_1:
		state = WBM_WRITE_STATE_DATA_2;
		break;
	case WBM_WRITE_STATE_DATA_2:
		state = WBM_WRITE_STATE_DATA_3;
		break;
	case WBM_WRITE_STATE_DATA_3:
		state = WBM_WRITE_STATE_WAIT_ACK;
		break;
	case WBM_WRITE_STATE_WAIT_ACK:
		if (ack)
			state = WBM_WRITE_STATE_COMMAND;
		break;
	}
}
