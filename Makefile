CXX = c++ -I${VERILATOR_ROOT}/include
ICEPACK = icepack
ICEPROG = iceprog
MAKE = gmake
VERILATOR = verilator -Wall -DSIMULATION --trace
VERILATOR_ROOT = /usr/local/share/verilator
VERILATOR_SRC = ${VERILATOR_ROOT}/include/verilated.cpp ${VERILATOR_ROOT}/include/verilated_vcd_c.cpp
NEXTPNR = nextpnr-ice40 --randomize-seed --up5k --package sg48
YOSYS = yosys
GTKWAVE = gtkwave -CM6
W = simulation

PCF = upduino.pcf
V =	top.v wbs_uart.v wbs_uart_tx.v wbs_uart_rx.v wbs_pwm.v \
	wbs_pwm_channel.v wbs_pdm.v wbs_pdm_channel.v wbs_charlie7x5.v \
	wbs_debug.v wbs_mic.v wbs_rgb.v wbx_1master.v wbm_blinkenlight.v \
	wbm_spi.v wbm_spi_tx.v wbm_spi_rx.v clock_domain_export.v \
	clock_domain_import.v

all: board.bit simulation.vcd test

clean:
	rm -fr simulation *.log *.json *.asc *.bit *.hex *.elf *.d *.vcd *.dot *.pdf

flash: board.bit
	${ICEPROG} -d i:0x0403:0x6014:0 board.bit

wave: $W.gtkw simulation.vcd
	${GTKWAVE} -a $W.gtkw simulation.vcd >/dev/null 2>&1 &

test: simulation_prove/logfile.txt simulation_cover/logfile.txt

lint:
	${VERILATOR} --lint-only board.v

simulation.sby: simulation.sby.sh Makefile
	sh simulation.sby.sh simulation.v $V >$@

simulation_prove/logfile.txt simulation_cover/logfile.txt: simulation.sby simulation.v ${V}
	sby -f simulation.sby

simulation.elf: ${V} simulation.cpp simulation.h simulation.uart.h

simulation.cpp: simulation.h simulation.spi.h simulation.uart.h simulation.wbm.h simulation.wb.h

board.json: ${V}

.SUFFIXES: .v .elf .vcd .json .asc .bit .dfu .hex .dot .pdf .py .gtkw

.v.elf:
	${VERILATOR} -cc --Mdir $*.d $<
	${MAKE} -C $*.d -f V$*.mk
	${CXX} -I$*.d -o $@ $*.cpp ${VERILATOR_SRC} $*.d/V$*__ALL.a

.elf.vcd:
	./$<

.v.json: ${V}
	${YOSYS} -p "read_verilog $< ${V}; synth_ice40 -top $* -json $@" >$*.yosys.log

.json.asc: ${PCF}
	${NEXTPNR} -q -l $*.nextpnr.log --pcf ${PCF} --json $< --asc $@

.asc.bit:
	${ICEPACK} $< $@

.py.gtkw:
	python $< $*

.bit.dfu:
	cp $< $@
	dfu-suffix -v 1209 -p 70b1 -a $@

.v.dot:
	yosys -p "read_verilog $<; show -format dot -prefix $*"

.dot.pdf:
	dot -Tpdf $< >$@
