#include "wishbone.h"

/*
 * Listen to requests from a wishbone b4 classic controller
 */

enum wbc_state {
	WBC_STATE_SEND_COMMAND,
	WBC_STATE_SEND_ADDRESS,
	WBC_STATE_WRITE_DATA,
	WBC_STATE_WAIT_WRITE_ACK,
	WBC_STATE_WAIT_READ_ACK,
	WBC_STATE_READ_DATA,
};

struct wbc {
	enum wbc_state state;
	uint8_t wb_we_o;
	uint8_t wb_sel_o;
	uint8_t wb_adr_o;
	uint32_t wb_dat_o;
	uint32_t wb_dat_i;
};

struct wbc wbc;

void
wbc_queue_read(uint8_t wb_adr_o, uint8_t wb_sel_o)
{
	wbc.wb_we_o = 0;
	wbc.wb_adr_o = wb_adr_o;
	wbc.wb_sel_o = wb_sel_o;
}

void
wbc_queue_write(uint8_t wb_adr_o, uint8_t wb_sel_o, uint32_t wb_dat_o)
{
	wbc.wb_we_o = 1;
	wbc.wb_adr_o = wb_adr_o;
	wbc.wb_sel_o = wb_sel_o;
	wbc.wb_dat_o = wb_dat_o;
}

uint8_t
wbc_io(uint8_t rx)
{
	switch (wbc.state) {
	case WBC_STATE_SEND_COMMAND:
send_command:
		wbc.state = WBC_STATE_SEND_ADDRESS;
		return wbc.wb_we_o << 7 | wbc.wb_sel_o;
	case WBC_STATE_SEND_ADDRESS:
		if (wbc.wb_we_o)
			wbc.state = WBC_STATE_WRITE_DATA;
		else
			wbc.state = WBC_STATE_WAIT_READ_ACK;
		return wbc.wb_adr_o;
	case WBC_STATE_WRITE_DATA:
		wbc.state = WBC_STATE_WAIT_WRITE_ACK;
		return wbc.wb_dat_o;
	case WBC_STATE_WAIT_WRITE_ACK:
		if (rx == 0xFF)
			// next clock is already the next cycle
			goto send_command;
		return 0;
	case WBC_STATE_WAIT_READ_ACK:
		if (rx == 0xFF)
			wbc.state = WBC_STATE_READ_DATA;
		return 0;
	case WBC_STATE_READ_DATA:
		wbc.wb_dat_i |= rx;
		// next clock is already the next cycle
		goto send_command;
	}
}
