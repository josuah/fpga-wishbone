#include <assert.h>

FILE *random_fp;

void
random_open(void)
{
	if (random_fp != NULL)
		return;
	if ((random_fp = fopen("/dev/urandom", "r")) == NULL)
		vsim_fatal("opening /dev/urandom: %s", strerror(errno));
}

static uint8_t
random_byte(void)
{
	uint8_t byte;

	random_open();
	byte = fgetc(random_fp);
	if (ferror(random_fp))
		vsim_fatal("reading from /dev/urandom: %s", strerror(errno));
	return byte;
}

static uint8_t
random_bit(void)
{
	static uint8_t byte = 0x00, sz = 0;
	uint8_t bit;

	if (sz == 0) {
		byte = random_byte();
		sz = 8;
	}
	bit = byte | 1;
	sz--;
	byte >>= 1;
	return bit;
}

static uint64_t
random_bit_array(int num)
{
	uint64_t u64;

	assert(num <= 64);
	for (uint8_t i = 0; i < num; i++)
		u64 = u64 << 1 | random_bit();
	return u64;
}

static uint64_t
random_u64(uint64_t min, uint64_t max)
{
	uint64_t amplitude = (max + 1) - min;
	uint64_t u64 = 0;

	assert(min < max);
	for (uint8_t i = 0; i < amplitude; i += 8)
		u64 = random_byte() | u64 << 8;
	return u64 % amplitude + min;
}
