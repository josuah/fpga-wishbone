import random
import cocotb
from cocotb.triggers import Timer
from cocotb.triggers import RisingEdge
from cocotb.triggers import FallingEdge
from cocotb.utils import get_sim_time
from cocotb.clock import Clock

class WishboneDriver:
    def __init__(self, clk_i, rst_ni, wb_we_i, wb_adr_i, wb_dat_i, wb_stb_i, wb_ack_o, wb_dat_o):
        cocotb.start_soon(Clock(clk_i, 1, units="ns").start())
        self.clk_i = clk_i
        self.rst_ni = rst_ni
        self.wb_we_i = wb_we_i
        self.wb_adr_i = wb_adr_i
        self.wb_dat_i = wb_dat_i
        self.wb_stb_i = wb_stb_i
        self.wb_ack_o = wb_ack_o
        self.wb_dat_o = wb_dat_o

    async def reset(self):
        await RisingEdge(self.clk_i)
        self.rst_ni.value = 0
        await RisingEdge(self.clk_i)
        self.rst_ni.value = 1
        await RisingEdge(self.clk_i)

    async def request(self, we, adr=0, dat=0, timeout=30):
        self.wb_we_i.value = we
        self.wb_adr_i.value = adr
        self.wb_dat_i.value = dat
        self.wb_stb_i.value = 1
        while timeout > 0:
            await RisingEdge(self.clk_i)
            if self.wb_ack_o.value == 1:
                #self.wb_dat_o
                break
            timeout -= 1
        self.wb_stb_i.value = 0
        await RisingEdge(self.clk_i)

    async def read(self, adr, timeout=30):
        await self.request(0, adr=adr, timeout=timeout)

    async def write(self, dat, adr, timeout=30):
        await self.request(1, adr=adr, dat=dat, timeout=timeout)

@cocotb.test(timeout_time=1000, timeout_unit="ms")
async def test_peri_pwm_channel(dut):
    """Batch test with randomized parameters"""
    for i in range(10):
        await test_peri_pwm_channel_run(dut)

async def test_peri_pwm_channel_run(dut, cycles=1000):
    """Issue a Wishbone request and check that it generates PWM output."""

    wb = WishboneDriver(dut.clk_i, dut.rst_ni, dut.wb_we_i, dut.wb_adr_i,
        dut.wb_dat_i, dut.wb_stb_i, dut.wb_ack_o, dut.wb_dat_o)

    for i in range(random.randint(0, 50)):
        await RisingEdge(dut.clk_i)

    val = random.getrandbits(8)
    dut._log.info(f"val={val}")

    await wb.reset()
    await wb.write(val, 0)

    tickup = 0
    switch = 0
    last_pwm = dut.pwm_o.value
    for i in range(cycles):
        switch += (dut.pwm_o.value != last_pwm)
        if i % 256 == 0:
            switch = 0
        assert switch <= 2

        tickup += dut.pwm_o.value
        last_pwm = dut.pwm_o.value

        await RisingEdge(dut.clk_i)

    # scoreboard
    dut._log.info(f"tickup={tickup}")
    dut._log.info(f"cycles={cycles}")
    expected_duty_cycle = val / 255 * 100
    dut._log.info(f"expected_duty_cycle={expected_duty_cycle}%")
    measured_duty_cycle = tickup / cycles * 100
    dut._log.info(f"measured_duty_cycle={measured_duty_cycle}%")
    assert measured_duty_cycle + 2 >= expected_duty_cycle
    assert measured_duty_cycle - 2 <= expected_duty_cycle
