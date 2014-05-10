# Tools

This project comes with a few tools you can use that mimic the behavior of helpers and formatters.  These are
really useful for testing functionality outside of ``notify-by-handler``.

The following tools reside under the ``bin/`` directory.

<a name="dump_nagios_env.sh"></a>
## ``dump_nagios_env.sh`` - Dump Nagios Environment

``dump_nagios_env.sh`` is a handy script that dumps the Nagios environment variables at the time an alert fires.
Follow the instuctions in the [script](/bin/dump_nagios_env.sh) to configure and use it.

The environment file that is generated can be used to test new formatters.

## ``draw_stack_bars`` - Draw Stack Bars 

``draw_stack_bars`` can generate horizontal stacked bars.

TODO: This needs better documentation. Are we missing command line arguments in the below output?

```
$ ./draw_stack_bars -h
usage: draw_stack_bars [options] label=value label=value

options:
  -h, --help            show this help message and exit
  -w WIDTH, --width=WIDTH
                        Picture width
  -o OUTPUT_FILE, --output=OUTPUT_FILE
                        The file name to save the results in
  --bar-area-ratio=BAR_AREA_RATIO
                        How wide should the bar area be compared to the total
                        width
  --bar-height-ratio=BAR_HEIGHT_RATIO
                        How tall should the bars be compared to their width
  --bar-border=BAR_BORDER
                        Width of the border around the bars
```

For example: ``./draw_stack_bars /var=10`` will generate:

![stack bars](/docs/images/stack-bars.png)

## ``get_ganglia_graph.rb`` - Draw Ganglia Graphs

``get_ganglia_graph.rb`` will download one or more images of Ganglia graphs.

```
$ ./get_ganglia_graph -h
Usage: get_ganglia_graph [-hmpr]

get_ganglia_graph is used to generate images from Ganglia graphs.

It takes one or more hostnames and a single metric to build the appropriate URI(s) from which to generate images.
The script outputs the full path for each of the images that have been written.

    -h, --host *HOST                 The FQDN of the host required to look up a metric/image in Ganglia. Specify multiple hosts with multiple '-h' arguments.
    -m, --metric                     The name of the metric we want to see.
    -p, --path                       An optional path in which to write the image files.
                                     DEFAULT: /tmp
    -r, --range                      The range of time for which the graph should look back.
                                     Acceptable values are the same as thouse used by Ganglia (i.e '8hours', '8h, '1day', '1d', '3weeks', '3w')
                                     DEFAULT: 8h (8 hours)

EXAMPLES
--------
1. Passing a single hostname and metric to get_ganglia_graph:

    get_ganglia_graph -h mysql01.example.com -m part_max_used

2. Passing multiple hostnames and a metric to get_ganglia_graph:

    get_ganglia_graph -h mysql01.example.com -h memcached01.example.com -m disk_free

3. Including an optional time range (12 hours):

    get_ganglia_graph -h mysql01.example.com -h memcached01.example.com -m disk_free -r 12h
```
