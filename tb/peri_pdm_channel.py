import random
import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock
from tb.driver.wishbone import WishboneDriver

@cocotb.test(timeout_time=1000, timeout_unit="us")
async def test_peri_pdm_channel(dut):
    """
    Batch test with randomized parameters
    """
    for i in range(10):
        await run_peri_pdm_channel(dut)

async def run_peri_pdm_channel(dut, cycles=1000):
    """
    Issue a Wishbone request and check that it generates PWM output.
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
    dut._log.info("test that the PDM signal switches up and down often enough")
    tickup = 0
    switch = 0
    last_pdm = dut.pdm_o.value
    for i in range(cycles):
        switch += (dut.pdm_o.value != last_pdm)
        if i % 256 == 255:
            if val < 128:
                assert switch * 2 > val
            else:
                assert switch * 2 > 256 - val
            switch = 0

        tickup += dut.pdm_o.value
        last_pdm = dut.pdm_o.value

        await RisingEdge(dut.clk_i)

    # scoreboard
    dut._log.info("test that the ratio is matching the input value with a small error margin")
    dut._log.debug(f"tickup={tickup}")
    dut._log.debug(f"cycles={cycles}")
    expected_duty_cycle = val / 255 * 100
    dut._log.debug(f"expected_duty_cycle={expected_duty_cycle}%")
    measured_duty_cycle = tickup / cycles * 100
    dut._log.debug(f"measured_duty_cycle={measured_duty_cycle}%")
    assert measured_duty_cycle + 50 >= expected_duty_cycle
    assert measured_duty_cycle - 50 <= expected_duty_cycle
