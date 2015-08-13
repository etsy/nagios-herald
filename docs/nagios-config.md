# Nagios Configuration

## Notification Command Configuration

Nagios needs to be instructed to use ``nagios-herald`` for notifications. The main notification program in
``nagios-herald`` is called ``nagios-herald``.

To configure Nagios to generate alerts via ``nagios-herald``, update the relevant stanza(s) in ``commands.cfg``.
The below example assumes ``nagios-herald`` is installed in ``/usr/local/bin``.

```
# email
define command {
    command_name    notify-host-by-email
    command_line    /usr/local/nagios-herald/bin/nagios-herald --message-type email --formatter=$_HOSTMESSAGE_FORMATTER_NAME$ --nagios-cgi-url=http://nagios.example.com/nagios/cgi-bin/cmd.cgi --reply-to=nagios@example.com
}

# specify the location of custom formatters
define command {
    command_name    notify-service-by-email
    command_line    /usr/local/nagios-herald/bin/nagios-herald --message-type email --formatter=$_SERVICEMESSAGE_FORMATTER_NAME$ --nagios-cgi-url=http://nagios.example.com/nagios/cgi-bin/cmd.cgi --reply-to=nagios@example.com --formatter-dir=/usr/local/nagios-herald-formatters
}

# pager
define command {
    command_name    notify-host-by-pager
    command_line    /usr/local/nagios-herald/bin/nagios-herald --message-type pager --formatter=$_HOSTMESSAGE_FORMATTER_NAME$ --nagios-cgi-url=http://nagios.example.com/nagios/cgi-bin/cmd.cgi --reply-to=nagios@example.com
}

define command {
    command_name    notify-service-by-pager
    command_line    /usr/local/nagios-herald/bin/nagios-herald --message-type pager --formatter=$_SERVICEMESSAGE_FORMATTER_NAME$ --nagios-cgi-url=http://nagios.example.com/nagios/cgi-bin/cmd.cgi --reply-to=nagios@example.com
}

# IRC (optional)
define command {
    command_name    notify-service-by-irc
    command_line    /usr/local/nagios-herald/bin/nagios-herald --message-type irc --formatter=$_SERVICEMESSAGE_FORMATTER_NAME$ --nagios-cgi-url=http://nagios.example.com/nagios/cgi-bin/cmd.cgi --reply-to=nagios@example.com
}

define command {
    command_name    notify-service-by-irc
    command_line    /usr/local/nagios-herald/bin/nagios-herald --message-type irc --formatter=$_SERVICEMESSAGE_FORMATTER_NAME$ --nagios-cgi-url=http://nagios.example.com/nagios/cgi-bin/cmd.cgi --reply-to=nagios@example.com
}
```

**NOTE**: ``$_HOSTMESSAGE_FORMATTER_NAME$`` and ``$_SERVICEMESSAGE_FORMATTER_NAME$`` are Nagios macros, generated
from a custom variable in a relevant service check definition.

You must also add command definitions for any custom message classes that you plan to use.  See the [messages](/docs/messages.md) page for details.

### Tracing Errors
If ``nagios-herald`` is failing to notify, you can turn up the logging via the ``--trace`` option to gather
more information, like so:

```
command_line    /usr/local/nagios-herald/bin/nagios-herald --message-type email --formatter=$_SERVICEMESSAGE_FORMATTER_NAME$ --nagios-cgi-url=http://nagios.example.com/nagios/cgi-bin/cmd.cgi --reply-to=nagios@example.com --trace
```

## Service Configuration

To apply a formatter to a service check, add the ``_message_formatter_name`` custom variable in the relevant stanza in ``services.cfg``:
The value of the variable is the name of the formatter.

```
define service {
    hostgroup_name                  web_servers
    service_description             Disk Space
    notification_interval           20
    check_command                   check_nrpe!check_disk
    _message_formatter_name         check_disk            <<<< custom variable
    contact_groups                  ops
}
```

**NOTE**: If no formatter is specified, ``nagios-herald`` defaults to the base formatter and generates generic content for messages.
