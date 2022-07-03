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

include Makefile.inc

all: src/mBoard.bit simulation.svcd test

clean:
	rm -fr simulation simulation_*/ *.log *.json *.asc *.bit *.hex *.elf *.d *.svcd *.dot *.pdf

flash: src/mBoard.bit
	${ICEPROG} -d i:0x0403:0x6014:0 src/mBoard.bit

wave: simulation.gtkw simulation.svcd
	${GTKWAVE} -a simulation.gtkw simulation.svcd >/dev/null 2>&1 &

test: simulation_prove/logfile.txt simulation_cover/logfile.txt

lint:
	${VERILATOR} --lint-only board.sv

make:
	find src -type f -name '*.sv' -name mBoard.sv -o -name -mSimulation-sv -o -exec echo V = {} + >Makefile.inc

simulation.sby: simulation.sby.sh Makefile
	sh simulation.sby.sh simulation.sv $V >$@

simulation_prove/logfile.txt simulation_cover/logfile.txt: simulation.sby simulation.sv ${V}
	sby -f simulation.sby

simulation.elf: ${V} simulation.cpp simulation.h simulation.uart.h

simulation.cpp: simulation.h simulation.spi.h simulation.uart.h simulation.wbm.h simulation.wb.h

src/mBoard.json: ${V}

.SUFFIXES: .sv .elf .svcd .json .asc .bit .dfu .hex .dot .pdf .py .gtkw

.sv.elf:
	${VERILATOR} -cc --Mdir $*.d $<
	${MAKE} -C $*.d -f V$*.mk
	${CXX} -I$*.d -o $@ $*.cpp ${VERILATOR_SRC} $*.d/V$*__ALL.a

.elf.svcd:
	./$<

.sv.json: ${V}
	${YOSYS} -p "read_verilog -sv $< ${V}; synth_ice40 -top $* -json $@" >$*.yosys.log

.json.asc: board.pcf
	${NEXTPNR} -q -l $*.nextpnr.log --pcf board.pcf --json $< --asc $@

.asc.bit:
	${ICEPACK} $< $@

.py.gtkw:
	python $< $*

.bit.dfu:
	cp $< $@
	dfu-suffix -v 1209 -p 70b1 -a $@

.sv.dot:
	yosys -p "read_verilog -sv $<; show -format dot -prefix $*"

.dot.pdf:
	dot -Tpdf $< >$@
