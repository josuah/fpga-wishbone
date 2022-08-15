import random
import cocotb
from cocotb.triggers import Timer
from cocotb.triggers import RisingEdge
from cocotb.triggers import FallingEdge
from cocotb.utils import get_sim_time
from cocotb.clock import Clock
from tb.driver.wishbone import WishboneDriver

@cocotb.test(timeout_time=1000, timeout_unit="us")
async def test_peri_pwm_channel(dut):
    """
    Batch test with randomized parameters
    """
    for i in range(10):
        await run_peri_pwm_channel(dut)

async def run_peri_pwm_channel(dut, cycles=1000):
    """
    Issue a Wishbone request and check that it generates PDM output.
    """

    # driver
    wb = WishboneDriver(dut._log, dut.clk_i, dut.rst_ni, dut.wb_we_i, dut.wb_adr_i,
        dut.wb_dat_i, dut.wb_stb_i, dut.wb_ack_o, dut.wb_dat_o)
    for i in range(random.randint(0, 50)):
        await RisingEdge(dut.clk_i)
    await wb.reset()
    val = random.getrandbits(8)
    await wb.write(0, val)

    # monitor
    tickup = 0
    switch = 0
    last_pwm = dut.pwm_o.value
    dut._log.info("test that the PWM signal stays switch only twice per cycle")
    for i in range(cycles):
        switch += (dut.pwm_o.value != last_pwm)
        if i % 256 == 0:
            switch = 0
        assert switch <= 2
        tickup += dut.pwm_o.value
        last_pwm = dut.pwm_o.value
        await RisingEdge(dut.clk_i)

    # scoreboard
    dut._log.info("test that the ratio is matching the input value with a small error margin")
    dut._log.debug(f"tickup={tickup}")
    dut._log.debug(f"cycles={cycles}")
    expected_ratio = val / 255 * 100
    dut._log.debug(f"expected_ratio={expected_ratio}%")
    measured_ratio = tickup / cycles * 100
    dut._log.debug(f"measured_ratio={measured_ratio}%")
    assert measured_ratio + 2 >= expected_ratio
    assert measured_ratio - 2 <= expected_ratio
