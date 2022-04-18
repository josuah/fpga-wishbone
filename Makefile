CXX = c++ -I${VERILATOR_ROOT}/include
ICEPACK = icepack
ICEPROG = iceprog
MAKE = gmake
VERILATOR = verilator -Wall -DSIMULATION --trace
VERILATOR_ROOT = /usr/local/share/verilator
VERILATOR_SRC = ${VERILATOR_ROOT}/include/verilated.cpp ${VERILATOR_ROOT}/include/verilated_vcd_c.cpp
NEXTPNR = nextpnr-ice40 --up5k --package sg48
YOSYS = yosys

PCF = upduino.pcf
V = wb_led_pwm.v wb_pwm.v wb_uart.v

all: board.bit simulation.vcd

clean:
	rm -fr *.log *.json *.asc *.bit *.hex *.elf *.d *.vcd

flash: board.bit
	${ICEPROG} -d i:0x0403:0x6014 board.bit

wave: simulation.vcd
	gtkwave simulation.vcd

test: ${V} testbench.v testbench.sby
	sby -f testbench.sby

board.json: ${V}

simulation.elf: ${V} simulation.cpp

.SUFFIXES: .v .elf .vcd .json .asc .bit .dfu .hex

.v.elf:
	${VERILATOR} -cc --Mdir $*.d $<
	${MAKE} -C $*.d -f V$*.mk
	${CXX} -I$*.d -o $@ $*.cpp ${VERILATOR_SRC} $*.d/V$*__ALL.a

.elf.vcd:
	./$<

.v.json: ${V}
	${YOSYS} -p "read_verilog $< ${V}; synth_ice40 -top $* -json $@" >cmd.yosys.log

.json.asc: ${PCF}
	${NEXTPNR} -q -l cmd.nextpnr.log --pcf ${PCF} --json $< --asc $@

.asc.bit:
	${ICEPACK} $< $@

.bit.dfu:
	cp $< $@
	dfu-suffix -v 1209 -p 70b1 -a $@
