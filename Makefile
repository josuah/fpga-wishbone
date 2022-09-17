GTKWAVE = gtkwave -CM
ICEPACK = icepack
ICEPROG = iceprog
VERILATOR = verilator -Wall -DSIMULATION -Irtl --trace --sv --trace-structs --Mdir verilator
VERILATOR_INC = /usr/local/share/verilator/include
VERILATOR_SRC = ${VERILATOR_INC}/verilated.cpp ${VERILATOR_INC}/verilated_vcd_c.cpp
CXX = c++ -I${VERILATOR_INC} #-DNDEBUG
NEXTPNR = nextpnr-ice40 --randomize-seed --up5k --package sg48
YOSYS = yosys
MAKE = gmake

RTL = top.sv clock_domain_crossing.sv \
 ctrl_async.sv ctrl_spi.sv ctrl_sync.sv ctrl_uart.sv \
 peri_charlieplex.sv peri_debug.sv peri_draw_line.sv peri_mems_microphone.sv \
 peri_pdm_channel.sv peri_pwm_channel.sv peri_rgb_led.sv \
 register_bank.sv spi_rx.sv spi_tx.sv uart_rx.sv uart_tx.sv

all: ice40.bit

clean:
	rm -f *.log *.json *.asc *.bit *.dfu *.dot *.pdf *.vcd *.elf
	rm -rf verilator

flash: ice40.bit
	${ICEPROG} -d i:0x0403:0x6014:0 ice40.bit

verilator/Vtop.a: top.sv

.SUFFIXES: .sv .elf .vcd .json .asc .bit .dfu .elf .vcd .dot .pdf .gtkw

.sv.elf:
	${VERILATOR} --cc --top-module ${*F} ${RTL}
	${MAKE} -C verilator -f V${*F}.mk
	${CXX} -DVM=V${*F} -I./verilator -I. -o $@ ${VERILATOR_SRC} verilator/V${*F}__ALL.a verilator/V${*F}__ALL.cpp $*.cpp

.elf.vcd:
	./$< >$@

.vcd.gtkw:
	${GTKWAVE} $<

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
