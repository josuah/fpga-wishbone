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
    clock = Clock(dut.clk, 10, units='ns').start()
    assert dut.pwm.value == 0b0
    dut.wb_c.dat.value = 0b00001111
    dut.wb_c.we.value = 0b1
    dut.wb_c.stb.value = 0b1
    await Timer(200, 'ns')
