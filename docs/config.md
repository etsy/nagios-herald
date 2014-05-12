# Configuration

``nagios-herald`` supports a YAML-based configuration file.  The configuration file is named
``config.yml`` and lives in the ``etc/`` directory of this project. This project provides an [example](/etc/config.yml.example) configuration file that you can use to get started.

## Command Line Options

``nagios-herald`` provides several command line options, some of which can override values in the configuration file.  During runtime, ``nagios-herald`` merges the configuration and command line options into a single hash available through the code.  Command line options always override configuration file values, when this is a conflict.

## Accessing Configuration Values

All configuration file values and command line options are available in a single, globally available hash named ``Config.config``.  See below for an example configuration file.

```
# define the FQDN of servers we call on to provide context in notifications
servers:
  ganglia: ganglia.example.com
  graphite: graphite.example.com
splunk:
  url: https://splunk.example.com:8089/services/search/jobs
  username: splunkuser
  password: splunkpass
```

To access the value for the Ganglia server URI, one would write code similar to the below:

```ruby
ganglia_uri = Config.config[:servers][:ganglia]
```
