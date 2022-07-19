import cocotb
from cocotb.triggers import RisingEdge
from cocotb.triggers import Timer
from cocotb.clock import Clock

async def drive_reset(dut):
    dut.rst = 1
    await RisingEdge(dut.clk)
    dut.rst = 0
    await RisingEdge(dut.clk)

@cocotb.test()
async def test(dut):
    clock = cocotb.start(Clock(dut.clk, 10, units='ns'))
    assert dut.pwm.value == 0
    await Timer(100, 'ns')
