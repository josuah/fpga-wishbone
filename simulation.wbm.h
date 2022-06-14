// Make request for Wishbone B4 pipelined master over SPI

enum wbm_state {
	WBM_STATE_SEND_COMMAND = 0,
	WBM_STATE_SEND_ADDRESS = 1,
	WBM_STATE_WRITE_DATA_0 = 2,
	WBM_STATE_WRITE_DATA_1 = 3,
	WBM_STATE_WRITE_DATA_2 = 4,
	WBM_STATE_WRITE_DATA_3 = 5,
	WBM_STATE_WAIT_WRITE_ACK = 6,
	WBM_STATE_WAIT_READ_ACK = 7,
	WBM_STATE_READ_DATA_0 = 8,
	WBM_STATE_READ_DATA_1 = 9,
	WBM_STATE_READ_DATA_2 = 10,
	WBM_STATE_READ_DATA_3 = 11,
};

struct wbm {
	enum wbm_state state;
	uint8_t wb_we_o;
	uint8_t wb_sel_o;
	uint8_t wb_adr_o;
	uint32_t wb_dat_o;
	uint32_t wb_dat_i;
} wbm;

void
wbm_queue_read(uint8_t wb_adr_o, uint8_t wb_sel_o)
{
	wbm.wb_we_o = 0;
	wbm.wb_adr_o = wb_adr_o;
	wbm.wb_sel_o = wb_sel_o;
}

void
wbm_queue_write(uint8_t wb_adr_o, uint8_t wb_sel_o, uint32_t wb_dat_o)
{
	wbm.wb_we_o = 1;
	wbm.wb_adr_o = wb_adr_o;
	wbm.wb_sel_o = wb_sel_o;
	wbm.wb_dat_o = wb_dat_o;
}

uint8_t
wbm_io(uint8_t rx)
{
	switch (wbm.state) {
	case WBM_STATE_SEND_COMMAND:
send_command:
		wbm.state = WBM_STATE_SEND_ADDRESS;
		return wbm.wb_we_o << 7 | wbm.wb_sel_o;
	case WBM_STATE_SEND_ADDRESS:
		if (wbm.wb_we_o)
			wbm.state = WBM_STATE_WRITE_DATA_0;
		else
			wbm.state = WBM_STATE_WAIT_READ_ACK;
		return wbm.wb_adr_o;
	case WBM_STATE_WRITE_DATA_0:
		wbm.state = WBM_STATE_WRITE_DATA_1;
		return wbm.wb_dat_o >> 24;
	case WBM_STATE_WRITE_DATA_1:
		wbm.state = WBM_STATE_WRITE_DATA_2;
		return wbm.wb_dat_o >> 16;
	case WBM_STATE_WRITE_DATA_2:
		wbm.state = WBM_STATE_WRITE_DATA_3;
		return wbm.wb_dat_o >> 8;
	case WBM_STATE_WRITE_DATA_3:
		wbm.state = WBM_STATE_WAIT_WRITE_ACK;
		return wbm.wb_dat_o >> 0;
	case WBM_STATE_WAIT_WRITE_ACK:
		if (rx == 0x01)
			// next clock is already the next cycle
			goto send_command;
		return 0;
	case WBM_STATE_WAIT_READ_ACK:
		if (rx == 0x01)
			wbm.state = WBM_STATE_READ_DATA_0;
		return 0;
	case WBM_STATE_READ_DATA_0:
		wbm.state = WBM_STATE_READ_DATA_1;
		wbm.wb_dat_i |= rx >> 24;
		return 0;
	case WBM_STATE_READ_DATA_1:
		wbm.state = WBM_STATE_READ_DATA_2;
		wbm.wb_dat_i |= rx >> 16;
		return 0;
	case WBM_STATE_READ_DATA_2:
		wbm.state = WBM_STATE_READ_DATA_3;
		wbm.wb_dat_i |= rx >> 8;
		return 0;
	case WBM_STATE_READ_DATA_3:
		wbm.wb_dat_i |= rx >> 0;
		// next clock is already the next cycle
		goto send_command;
	}
}
