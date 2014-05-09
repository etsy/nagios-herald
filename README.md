# nagios-herald

``nagios-herald`` is a project that aims to make it easy to provide context in Nagios alerts.

It was created from a desire to supplement an on-call engineer's awareness of conditions surrounding a notifying event. In other words, if a computer is going to page me at 3AM, I expect it to do some work for me to help me understand what's failing.

## Why Customize Nagios Alerts?

Nagios is a time-tested monitoring and alerting tool used by many Operations teams to keep an eye
on the shop.  It does an excellent job of executing scheduled checks, determining when a threshold has been exceeded, and sending alerts.

Past experience with Nagios has shown that, typically, those alerts provide little information beyond the fact that a host is down or a service is not responding as defined by check thresholds. It's bad enough to be woken up by an alert; it would make the on-call experience more bearable if the alerts could tell the engineer more about what's going on.  But what's useful in an alert?

When notified, an engineer often performs a set of procedures to gather information about the event before attempting to correct it.  Imagine being able to automatically perform those procedures (or some subset) at the time of the alert. Imagine further, that the results of those procedures are embedded in the alert!

Enter ``nagios-herald``!

### Generic Nagios Alert

Using the canonical (and oft-cited) disk space check, here's an example notification:

![vanilla-nagios-alert](/docs/images/vanilla-nagios.png)

While it does provide necessary information, it could be formatted for better legibility.  For example,
the following line, which contains the information we need, is dense and may be difficult to
parse in the wee hours of the morning:

    Additional Info: DISK WARNING - free space: / 1597 MB (8% inode=57%):
    /dev/shm 24127 MB (100% inode=99%): /boot 152 MB (83% inode=99%):

Common questions would be **"Which volume is problematic?"** or
**"Why is this considered a 'WARNING' alert?"**  In this example, it's not readily apparent what
those answers are.  Let's add that context with ``nagios-herald``.

### Nagios Alert with Context

``nagios-herald`` can **highlight and colorize text**, **embed images** (such as Ganglia graphs), **include search results**, and much more.

The previous disk space alert example can be tailored to look like this:

![html nagios email](docs/images/nagios-herald.png)

Notice the handy **stack bar** that clearly illustrates the problematic volume?  See that **Ganglia graph**
showing disk space utilization for the node in the last 24 hours. Curious why the alert fired?  Check
the **highlighted ``df`` output** that neatly defines which threshold was exceeded and why.

**NOTE**: In this example, the Nagios check ran ``df`` and supplied that input.

This is possible because ``nagios-herald`` provides extensible formatters.

## Formatters

Adding context to alerts is done by the formatters. Formatters generate all the content that may
be used by one or more message types. For example, text returned by a Nagios check
can be highlighted to grab the operator's attention.

To learn more, see for the [formatters](/docs/formatters.md) page.

## Helpers

Helpers are libraries available to all formatters that can be used to supplement the content they generate. For example, a helper can pull in external information (such as a graph) that is relevant to a service that Nagios is alerting on.

``nagios-herald`` comes with the following helpers as examples:

* GangliaGraph - Downloads relevant graphs to be embedded in (email) messages.
* SplunkReporter - Queries Splunk for information to add to an alert.
* UrlImage - Generic helper to download images.

## Tools

The repository comes with a few tools you can use to provide additional context to your formatter.  These are
really useful for testing functionality outside of ``notify-by-handler``.

### Stack Bars ``bin/draw_stack_bars``

Stack bars can be useful for visualizing disk utilization.

    $ ./bin/draw_stack_bars -h
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


For example: **./bin/draw_stack_bars /var=10** will generate:

![stack bars](docs/images/stack-bars.png)

### Ganglia Graphs ``bin/get_ganglia_graph``

    $ ./bin/get_ganglia_graph -h
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

        get_ganglia_graph -h dbshard12.ny4.etsy.com -m part_max_used

    2. Passing multiple hostnames and a metric to get_ganglia_graph:

        get_ganglia_graph -h dbshard12.ny4.etsy.com -h memcached01.ny4.etsy.com -m disk_free

    3. Including an optional time range (12 hours):

        get_ganglia_graph -h dbshard12.ny4.etsy.com -h memcached01.ny4.etsy.com -m disk_free -r 12h

**NOTE**: Formatters can inline Ganglia graphs by calling the ``generate_ganglia_graphs()`` method,
imported from the ``lib/ganglia_graph.rb`` library.

# Dependencies

## Ruby Gems

``nagios-herald`` and its tools depend on the following Ruby gems:

* ``app_conf``
* ``choice``
* ``mail``

The above gems are installed on all Nagios instances via Chef.

## Stack Bars

Generating stack bars requires the following (which are included in this project for your convenience):

* Python
* Python Image Library (PIL)
