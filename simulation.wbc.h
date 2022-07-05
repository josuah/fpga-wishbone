// Make request for Wishbone B4 pipelined master over SPI

typedef enum {
	eWbcState_SendCommand,
	eWbcState_SendAddress,
	eWbcState_WriteData,
	eWbcState_WaitWriteAck,
	eWbcState_WaitReadAck,
	eWbcState_ReadData,
} eWbcState;

typedef struct {
	eWbcState state;
	uint8_t wb_we_o;
	uint8_t wb_sel_o;
	uint8_t wb_adr_o;
	uint32_t wb_dat_o;
	uint32_t wb_dat_i;
} sWishboneCtrl;

sWishboneCtrl wbc;

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
	case eWbcState_SendCommand:
send_command:
		wbc.state = eWbcState_SendAddress;
		return wbc.wb_we_o << 7 | wbc.wb_sel_o;
	case eWbcState_SendAddress:
		if (wbc.wb_we_o)
			wbc.state = eWbcState_WriteData;
		else
			wbc.state = eWbcState_WaitReadAck;
		return wbc.wb_adr_o;
	case eWbcState_WriteData:
		wbc.state = eWbcState_WaitWriteAck;
		return wbc.wb_dat_o;
	case eWbcState_WaitWriteAck:
		if (rx == 0xFF)
			// next clock is already the next cycle
			goto send_command;
		return 0;
	case eWbcState_WaitReadAck:
		if (rx == 0xFF)
			wbc.state = eWbcState_ReadData;
		return 0;
	case eWbcState_ReadData:
		wbc.wb_dat_i |= rx;
		// next clock is already the next cycle
		goto send_command;
	}
}
