# Helpers

Helpers are libraries available to all formatters that can be used to supplement the content they generate. For example, a helper can pull in external information (such as a graph) that is relevant to a service that Nagios is alerting on.

``nagios-herald`` comes with the following helpers as examples:

* GangliaGraph - Downloads relevant graphs to be embedded in (email) messages.
* SplunkReporter - Queries Splunk for information to add to an alert.
* LogstashQuery - Queries logstash with either a kibaba-style query or a file containing query JSON
* UrlImage - Generic helper to download images.

Helpers are located in ``lib/nagios-herald/helpers/``.

## Writing and Using Custom Helpers

You may write your own helpers and use them with nagios-herald.  These helper classes can live in any location.  A custom helper should subclass Helper::Base.

### Custom Helper Configuration

To use a custom helper, you must add the --helper-dir flag to any notification command stanzas in ``commands.cfg`` that will use that helper class. ``helper-dir`` specifies the directory in which your custom helper class is stored. You can also define the location of custom helper classes in the ``config.yml`` configuration file.

```
# notify by carrier pigeon
define command {
    command_name    notify-host-by-pigeon
    command_line    /usr/local/nagios-herald/bin/nagios-herald --message-dir=/usr/local/nagios-herald-messages/ --message-type=pigeon --formatter=$_HOSTMESSAGE_FORMATTER_NAME$ -- nagios-cgi-url=http://nagios.example.com/nagios/cgi-bin/cmd.cgi --reply-to=nagios@example.com --helper-dir=/usr/local/nagios-herald-helpers/
}

define command {
    command_name    notify-service-by-pigeon
    command_line    /usr/local/nagios-herald/bin/nagios-herald --message-dir=/usr/local/nagios-herald-messages/ --message-type=pigeon --                                           formatter=$_SERVICEMESSAGE_FORMATTER_NAME$ --nagios-cgi-url=http://nagios.example.com/nagios/cgi-bin/cmd.cgi --reply-to=nagios@example.com --helper-dir=/usr/local/nagios-herald-helpers/
}
```

