struct spi {
	uint8_t tx, rx;
	uint8_t bits;
} spi;

static void
spi_tick_posedge(void)
{
	vsim->spi_sck = 1;
	vsim->spi_sdi = spi.tx >> 7;
	simulation_eval();

	spi.rx = (spi.rx << 1) | vsim->spi_sdo;
	spi.tx = spi.tx << 1;

	if (++spi.bits == 8)
		spi.bits = 0;
}

static void
spi_tick_negedge(void)
{
	vsim->spi_sck = 0;
	simulation_eval();
}
