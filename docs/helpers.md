# Helpers

Helpers are libraries available to all formatters that can be used to supplement the content they generate. For example, a helper can pull in external information (such as a graph) that is relevant to a service that Nagios is alerting on.

``nagios-herald`` comes with the following helpers as examples:

* GangliaGraph - Downloads relevant graphs to be embedded in (email) messages.
* SplunkReporter - Queries Splunk for information to add to an alert.
* UrlImage - Generic helper to download images.

Helpers are located in ``lib/nagios-herald/helpers/``.
