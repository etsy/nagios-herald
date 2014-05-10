#!/bin/bash
# Dump the environment as Nagios sees it; useful for generating environment files to test with new formatters
#
# CONFIG NOTES
# In commands.cfg, add a definition similar to the following:
#
# 'dump-env' command definition; dump Nagios' environment (use sparingly)
#define command {
#        command_name    dump-env
#        command_line    /usr/local/nagios-herald/bin/dump_nagios_env.sh
#}
#
# In contacts.cfg, append the 'dump-env' short command to one's 'service_notification_commands' like so:
#
#define contact {
#        contact_name                    ops
#        alias                           Ops Engineer
#        email                           ops@example.com
#        use                             generic-contact
#        service_notification_commands   notify-service-by-email,dump-env
#}

LOGFILE="/tmp/nagios_env_$(date +%Y%m%d).log"
date >> $LOGFILE
env >> $LOGFILE
