struct spi {
	uint8_t tx, rx;
	uint8_t bits;
} spi;

static void
spi_posedge(void)
{
	vsim->spi_sck_i = 1;
	vsim->spi_sd_i = spi.tx >> 7;
	vsim_eval();

	spi.rx = (spi.rx << 1) | vsim->spi_sd_o;
	spi.tx = spi.tx << 1;

	if (++spi.bits == 8)
		spi.bits = 0;

	vsim_eval();
}

static void
spi_negedge(void)
{
	vsim->spi_sck_i = 0;

	vsim_eval();
}
