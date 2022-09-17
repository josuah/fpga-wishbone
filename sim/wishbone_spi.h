/*
 * Wishbone bridge over SPI
 */

enum wishbone_spi_state {
	WISHBONE_SPI_STATE_IDLE,
	WISHBONE_SPI_STATE_SEND_COMMAND,
	WISHBONE_SPI_STATE_SEND_ADDRESS,
	WISHBONE_SPI_STATE_WRITE_DATA,
	WISHBONE_SPI_STATE_WAIT_WRITE_ACK,
	WISHBONE_SPI_STATE_WAIT_READ_ACK,
	WISHBONE_SPI_STATE_READ_DATA,
};

struct wishbone_spi {
	enum wishbone_spi_state state;
	uint8_t wb_we_o;
	uint8_t wb_sel_o;
	wishbone_addr_t wb_adr_o;
	wishbone_data_t wb_dat_o;
	wishbone_data_t wb_dat_i;
};

struct wishbone_spi wishbone_spi;

void
wishbone_spi_queue_read(uint8_t wb_adr_o, uint8_t wb_sel_o)
{
	wishbone_spi.wb_we_o = 0;
	wishbone_spi.wb_adr_o = wb_adr_o;
	wishbone_spi.wb_sel_o = wb_sel_o;
}

void
wishbone_spi_queue_write(uint8_t wb_adr_o, uint8_t wb_sel_o, uint32_t wb_dat_o)
{
	wishbone_spi.wb_we_o = 1;
	wishbone_spi.wb_adr_o = wb_adr_o;
	wishbone_spi.wb_sel_o = wb_sel_o;
	wishbone_spi.wb_dat_o = wb_dat_o;
}

uint8_t
wishbone_spi_posedge(uint8_t rx)
{
	switch (wishbone_spi.state) {
	case WISHBONE_SPI_STATE_IDLE:
	case WISHBONE_SPI_STATE_SEND_COMMAND:
send_command:
		wishbone_spi.state = WISHBONE_SPI_STATE_SEND_ADDRESS;
		return wishbone_spi.wb_we_o << 7 | wishbone_spi.wb_sel_o;
	case WISHBONE_SPI_STATE_SEND_ADDRESS:
		if (wishbone_spi.wb_we_o)
			wishbone_spi.state = WISHBONE_SPI_STATE_WRITE_DATA;
		else
			wishbone_spi.state = WISHBONE_SPI_STATE_WAIT_READ_ACK;
		return wishbone_spi.wb_adr_o;
	case WISHBONE_SPI_STATE_WRITE_DATA:
		wishbone_spi.state = WISHBONE_SPI_STATE_WAIT_WRITE_ACK;
		return wishbone_spi.wb_dat_o;
	case WISHBONE_SPI_STATE_WAIT_WRITE_ACK:
		if (rx == 0xFF)
			// next clock is already the next cycle
			goto send_command;
		return 0;
	case WISHBONE_SPI_STATE_WAIT_READ_ACK:
		if (rx == 0xFF)
			wishbone_spi.state = WISHBONE_SPI_STATE_READ_DATA;
		return 0;
	case WISHBONE_SPI_STATE_READ_DATA:
		wishbone_spi.wb_dat_i |= rx;
		// next clock is already the next cycle
		goto send_command;
	}
}
