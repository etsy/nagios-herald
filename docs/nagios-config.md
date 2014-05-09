# Nagios Configuration

## Notification Command Configuration

To configure Nagios to generate alerts via ``nagios-herald``, update the relevant stanza(s) in ``commands.cfg``.
The below example assumes ``nagios-herald`` is installed in ``/usr/local/bin`.

by calling the ``notify-by-handler`` script as defined in Nagios' ``commands.cfg``
file.

```
define command {
    command_name    notify-host-by-email
    command_line    /usr/local/nagios-herald/bin/notify-by-handler --formatter=$_HOSTEMAIL_FORMATTER_NAME$ --nagios-cgi-url=http://nagios.example.com/nagios/cgi-bin/cmd.cgi --reply-to=nagios@example.com
}

define command {
    command_name    notify-service-by-email
    command_line    /usr/local/nagios-herald/bin/notify-by-handler --formatter=$_SERVICEEMAIL_FORMATTER_NAME$ --nagios-cgi-url=http://nagios.example.com/nagios/cgi-bin/cmd.cgi --reply-to=nagios@example.com
}
```

**NOTE**: ``$_HOSTEMAIL_FORMATTER_NAME$`` and ``$_SERVICEEMAIL_FORMATTER_NAME$`` are Nagios macros, generated
from a custom variable in the service check definition. See below for an example of this:

```
define service {
    hostgroup_name                  web_servers
    service_description             Disk Space
    notification_interval           20
    check_command                   check_nrpe!check_disk
    _email_formatter_name           check_disk            <<<< custom variable
    contact_groups                  ops
}
```

TODO: The ``_email_formatter_name`` needs to be updated to be more generic. It reflects the earliest days of ``nagios-herald`` when it was email-centric.

## Service Configuration

To apply a formatter to a service check, add the ``_email_formatter_name`` custom variable in the relevant stanza in the ``services.cfg``:

**NOTE**: If no formatter is specified, ``nagios-herald`` defaults to the base formatter and generates generic content for messages.

```
define service {
    use                             generic-service
    host_name                       devmysql.example.com
    service_description             Disk Space
    check_interval                  60; every hour
    check_command                   check_nrpe!check_disk
    _email_formatter_name           check_disk
}
```
