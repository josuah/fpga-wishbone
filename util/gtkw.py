"""
    This work is funded through NLnet under Grant 2019-02-012

    License: LGPLv3+


"""
from vcd.gtkw import GTKWSave, GTKWColor
from math import log2


def write_gtkw(gtkw_name, vcd_name, gtkw_dom, gtkw_style=None,
               module=None, loc=None, color=None, base=None,
               zoom=None, marker=-1, clk_period=1e-6,
               time_resolution_unit="ps"):
    """ Write a GTKWave document according to the supplied style and DOM.

    :param gtkw_name: name of the generated GTKWave document
    :param vcd_name: name of the waveform file
    :param gtkw_dom: DOM style description for the trace pane
    :param gtkw_style: style for signals, classes and groups
    :param module: default module
    :param color: default trace color
    :param base: default numerical base
    :param loc: source code location to include as a comment
    :param zoom: initial zoom level, in GTKWave format. Can also be "formal"
                 when the file comes from a formal engine
    :param marker: initial location of a marker
    :param clk_period: clock period in seconds, helping
                       to set a reasonable initial zoom level.
                       Use together with ``time_resolution_unit``.
    :param time_resolution_unit: use "ps" or "ns". Derived from the units of
                                 the "timescale" on the VCD file. Used with
                                 "clk_period" to set a default zoom level

    **gtkw_style format**

    Syntax: ``{selector: {attribute: value, ...}, ...}``

    "selector" can be a signal, class or group

    Signal groups propagate most attributes to their children

    Attribute choices:

    * module: absolute path of the current module
    * submodule: same as above, but relative
    * color: trace color
    * base: numerical base for value display
    * display: alternate text to display in the signal pane
    * comment: comment to display in the signal pane
    * bit: select a bit from a wide signal. MSB is zero, unfortunately
    * closed (for groups): this group starts closed

    **gtkw_dom format**

    Syntax: ``[signal, (signal, class), (group, [children]), comment, ...]``

    The DOM is a list of nodes.

    Nodes are signals, signal groups or comments.

    * signals are strings, or tuples: ``(signal name, class, class, ...)``
    * signal groups are tuples: ``(group name, class, class, ..., [nodes])``
    * comments are: ``{'comment': 'comment string'}``

    In place of a class name, an inline class description can be used.
    ``(signal, {attribute: value, ...}, ...)``

    An anonymous group can be used to apply a style to a group of signals.
    ``({attribute: value}, [signal, signal, ...])``
    """
    colors = {
        'blue': GTKWColor.blue,
        'cycle': GTKWColor.cycle,
        'green': GTKWColor.green,
        'indigo': GTKWColor.indigo,
        'normal': GTKWColor.normal,
        'orange': GTKWColor.orange,
        'red': GTKWColor.red,
        'violet': GTKWColor.violet,
        'yellow': GTKWColor.yellow,
    }

    with open(gtkw_name, "wt") as gtkw_file:
        gtkw = GTKWSave(gtkw_file)
        if loc is not None:
            gtkw.comment("Auto-generated by " + loc)
        gtkw.dumpfile(vcd_name)
        # set a reasonable zoom level
        # also, move the marker to an interesting place
        if zoom == "formal":
            # output from formal engines looks good at this zoom level
            zoom = -6.3
        if zoom is None:
            zoom = -42.8 - log2(clk_period)
            # base zoom level is affected by time resolution units
            if time_resolution_unit == "ns":
                zoom = zoom + log2(1e3)
        gtkw.zoom_markers(zoom, marker)

        # create an empty style, if needed
        if gtkw_style is None:
            gtkw_style = dict()

        # create an empty root selector, if needed
        root_style = gtkw_style.get('', dict())

        # apply styles to the root selector, if provided
        if module is not None:
            root_style['module'] = module
        if color is not None:
            root_style['color'] = color
        if base is not None:
            root_style['base'] = base
        # base cannot be None, use 'hex' by default
        if root_style.get('base') is None:
            root_style['base'] = 'hex'

        # recursively walk the DOM
        def walk(dom, style):
            for node in dom:
                node_name = None
                children = None
                # copy the style from the parent
                node_style = style.copy()
                # node is a signal name string
                if isinstance(node, str):
                    node_name = node
                    # apply style from node name, if specified
                    if node_name in gtkw_style:
                        node_style.update(gtkw_style[node_name])
                # node is a tuple
                # could be a signal or a group
                elif isinstance(node, tuple):
                    node_name = node[0]
                    # collect styles from the selectors
                    # order goes from the most specific to most generic
                    # which means earlier selectors override later ones
                    for selector in reversed(node):
                        # update the node style from the selector
                        if isinstance(selector, str):
                            if selector in gtkw_style:
                                node_style.update(gtkw_style[selector])
                        # apply an inline style description
                        elif isinstance(selector, dict):
                            node_style.update(selector)
                    # node is a group if it has a child list
                    if isinstance(node[-1], list):
                        children = node[-1]
                # comment
                elif isinstance(node, dict):
                    if 'comment' in node:
                        gtkw.blank(node['comment'])
                # merge the submodule into the module path
                if 'submodule' in node_style:
                    node_module = node_style['submodule']
                    if 'module' in node_style:
                        node_top_module = node_style['module']
                        node_module = node_top_module + '.' + node_module
                    # update the module path
                    node_style['module'] = node_module
                    # don't propagate this attribute to children
                    del node_style['submodule']
                # emit the group delimiters and walk over the child list
                if children is not None:
                    # see whether this group starts closed
                    closed = False
                    if 'closed' in node_style:
                        closed = node_style['closed']
                        del node_style['closed']  # do not inherit
                    # only emit a group if it has a name
                    if isinstance(node_name, str):
                        gtkw.begin_group(node_name, closed)
                    # pass on the group style to its children
                    walk(children, node_style)
                    if isinstance(node_name, str):
                        gtkw.end_group(node_name)
                # emit a trace, if the node is a signal
                elif node_name is not None:
                    signal_name = node_name
                    # prepend module name to signal
                    if 'module' in node_style:
                        node_module = node_style['module']
                        if node_module is not None:
                            signal_name = node_module + '.' + signal_name
                    node_color = colors.get(node_style.get('color'))
                    node_base = node_style.get('base')
                    display = node_style.get('display')
                    if 'bit' in node_style:
                        bit = node_style['bit']
                        signal_name = f'({bit}){signal_name}'
                    gtkw.trace(signal_name, color=node_color,
                               datafmt=node_base, alias=display)

        walk(gtkw_dom, root_style)
