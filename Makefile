ICEPACK = icepack
ICEPROG = iceprog
VERILATOR = verilator -Wall -DSIMULATION -Irtl --trace --sv --trace-structs --Mdir verilator
VERILATOR_ROOT = /usr/local/share/verilator
VERILATOR_SRC = ${VERILATOR_ROOT}/include/verilated.cpp ${VERILATOR_ROOT}/include/verilated_vcd_c.cpp
CXX = c++ -I${VERILATOR_ROOT}/include
NEXTPNR = nextpnr-ice40 --randomize-seed --up5k --package sg48
YOSYS = yosys
MAKE = gmake

RTL = rtl/clock_domain_crossing.sv rtl/ctrl_async.sv rtl/ctrl_spi.sv \
  rtl/ctrl_sync.sv rtl/ctrl_uart.sv rtl/peri_charlieplex.sv \
  rtl/peri_debug.sv rtl/peri_draw_line.sv rtl/peri_mems_microphone.sv \
  rtl/peri_pdm_channel.sv rtl/peri_pwm_channel.sv rtl/peri_rgb_led.sv \
  rtl/register_bank.sv rtl/spi_rx.sv rtl/spi_tx.sv rtl/top.sv rtl/uart_rx.sv \
  rtl/uart_tx.sv

all: ice40.bit

clean:
	rm -f *.log *.json *.asc *.bit *.dfu *.dot *.pdf *.vcd *.elf
	rm -rf verilator

flash: ice40.bit
	${ICEPROG} -d i:0x0403:0x6014:0 ice40.bit

verilator/Vtop.a: rtl/top.sv

.SUFFIXES: .sv .elf .vcd .json .asc .bit .dfu .elf .vcd .dot .pdf

.sv.elf:
	${VERILATOR} --cc --top-module top ${RTL}
	${MAKE} -C verilator -f V${*F}.mk
	${CXX} -DVM=V${*F} -I./verilator -I. -o $@ ${VERILATOR_SRC} verilator/V${*F}__ALL.a verilator/V${*F}__ALL.cpp $*.cpp

.elf.vcd:
	./$< >$@

.sv.json:
	${YOSYS} -p "read_verilog -sv $< ${RTL}; synth_ice40 -top $* -json $@" >$*.yosys.log
	@grep -i -e warn -e error $*.yosys.log

.json.asc:
	${NEXTPNR} -q -l $*.nextpnr.log --pcf ice40.pcf --json $< --asc $@
	@grep -i -e warn -e error $*.nextpnr.log

.asc.bit:
	${ICEPACK} $< $@

.bit.dfu:
	cp $< $@
	dfu-suffix -v 1209 -p 70b1 -a $@

.sv.dot:
	${YOSYS} -p "read_verilog -sv $<; show -format dot -prefix $*"

.dot.pdf:
	dot -Tpdf $< >$@

.py.xml:
	mv dump.vcd $*.d/dump.vcd
