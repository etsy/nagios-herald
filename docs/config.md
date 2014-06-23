# Configuration

``nagios-herald`` supports a YAML-based configuration file.  The configuration file is named
``config.yml`` and lives in the ``etc/`` directory of this project. This project provides
an [example](/etc/config.yml.example) configuration file that you can use to get started.

## Command Line Options

``nagios-herald`` provides several command line options, some of which can override values
in the configuration file.  During runtime, ``nagios-herald`` merges the configuration
and command line options into a single hash available through the code.
Command line options **always override configuration file values, when there is a conflict**.

## Accessing Configuration Values

All configuration file values and command line options are available in a single, globally
available hash named ``Config.config``.  See below for an example configuration file.

```
# define the FQDN of servers we call on to provide context in notifications
servers:
  ganglia: ganglia.example.com
  graphite: graphite.example.com
splunk:
  url: https://splunk.example.com:8089/services/search/jobs
  username: splunkuser
  password: splunkpass
logstash:
  url: http://logstash.example.com:9200
  result_field_truncate: 200
```

To access the value for the Ganglia server URI, one would write code similar to the below:

```ruby
ganglia_uri = Config.config[:servers][:ganglia]
```

### Notable Configuration Values

Two of the most important configuration values are ``formatter_dir`` and ``logfile``.

``formatter_dir`` (equivalent to the ``--formatter-dir`` command line option) tells **nagios-herald**
where to locate **your custom formatters**. It will load those in addition to the built-in formatters.
Custom formatters are given precedence allowing formatter authors to override the built-in formatters.

``logfile`` tells **nagios-herald** where to log its output. This is especially critical to catch errors
should they arise. If **nagios-herald** isn't sending notifications, **it's a bug**; consult ``logfile`` for
details. Optionally, setting ``trace`` to **true** (equivalent to ``--trace`` on the command line) will
provide a backtrace to aid in debugging.
