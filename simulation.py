from gtkw import write_gtkw
from sys import argv

def group(pfx):
    return (pfx, [(pfx)])

traces = [
    group('rst'),
    group('spi_*'),
    group('ms.mss.*'),
    group('ms.mst.*'),
    group('ms.msr.cd_*'),
    group('ms.msr.mcde.*'),
    group('ms.msr.shifter*'),
    group('ms.msr.spi_*'),
    group('ms.mcdi.*'),
    group('ms.mcde.*'),
]

style = {
    'clk': {'color': 'red'},
    'io': {'color': 'yellow'},
    'state': {'color': 'violet', 'base': 'dec'}
}

write_gtkw(argv[1]+'.gtkw', argv[1]+'.vcd', traces, style,
    module='TOP.mTopLevel', clk_period=1.0e-10)
