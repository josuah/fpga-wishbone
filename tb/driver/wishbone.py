import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock

class WishboneDriver:
    def __init__(self, log, clk_i, rst_ni, wb_we_i, wb_adr_i, wb_dat_i, wb_stb_i, wb_ack_o, wb_dat_o):
        self.log = log
        self.clk_i = clk_i
        self.rst_ni = rst_ni
        self.wb_we_i = wb_we_i
        self.wb_adr_i = wb_adr_i
        self.wb_dat_i = wb_dat_i
        self.wb_stb_i = wb_stb_i
        self.wb_ack_o = wb_ack_o
        self.wb_dat_o = wb_dat_o
        self.log.debug("WishboneDriver: starting the clock")
        cocotb.start_soon(Clock(self.clk_i, 1, "ns").start())

    async def reset(self):
        self.log.debug("WishboneDriver: issuing a reset")
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
                self.wb_stb_i.value = 0
                return self.wb_dat_o.value
            timeout -= 1
        assert(not "WishboneDriver: timeout reached")

    async def read(self, adr, timeout=30):
        self.log.debug(f"WishboneDriver: reading from {adr}")
        return await self.request(0, adr=adr, timeout=timeout)

    async def write(self, adr, dat, timeout=30):
        self.log.debug(f"WishboneDriver: writing '{dat}' to address {adr}")
        await self.request(1, adr=adr, dat=dat, timeout=timeout)
