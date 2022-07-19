import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb.triggers import Timer

async def generate_reset(dut, duration=10):
    dut.rst.value = 1
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)

@cocotb.test()
async def test_main(dut):
    clock = cocotb.start(Clock(dut.clk, 10, units='ns'))
    await cocotb.start(generate_reset(dut))
