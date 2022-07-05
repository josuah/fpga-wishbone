from gtkw import write_gtkw
from sys import argv

def group(pfx):
    return (pfx, [(pfx + '.*')])

traces = [
    group('mspi.spi'),
    group('mspi.mrx.mexp'),
    group('mspi.mrx.mexp.cdc'),
    group('mspi.mimp'),
    group('mspi.rx'),
]

style = {
    'clk': {'color': 'red'},
    'io': {'color': 'yellow'},
    'state': {'color': 'violet', 'base': 'dec'}
}

write_gtkw(argv[1]+'.gtkw', argv[1]+'.vcd', traces, style,
    module='TOP.simulation.top', clk_period=1.0e-10)
