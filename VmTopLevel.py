from gtkw import write_gtkw
from sys import argv

def group(pfx):
    return (pfx, [(pfx)])

traces = [
    group('rst'),
    group('spi_*'),
    group('mwcs.mss.*'),
    group('mwcs.mst.*'),
    group('mwcs.msr.cd_*'),
    group('mwcs.msr.mcde.*'),
    group('mwcs.msr.shifter*'),
    group('mwcs.msr.spi_*'),
    group('mwcs.mcdi.*'),
    group('mwcs.mcde.*'),
]

style = {
    'clk': {'color': 'red'},
    'io': {'color': 'yellow'},
    'state': {'color': 'violet', 'base': 'dec'}
}

write_gtkw(argv[1]+'.gtkw', argv[1]+'.vcd', traces, style,
    module='TOP.mTopLevel', clk_period=1.0e-10)
