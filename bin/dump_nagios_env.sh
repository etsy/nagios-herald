#!/bin/bash
# Dump the environment as Nagios sees it; useful for debugging when we don't get notifications - rfrantz 20130626
#
# CONFIG NOTES
# In commands.cfg, add a definition similar to the following:
#
# 'dump-env' command definition; dump Nagios' environment (use sparingly)
#define command {
#        command_name    dump-env
#        command_line    /usr/etsy/nagios-herald/dump_nagios_env.sh
#}
#
# In contacts.cfg, append the 'dump-env' short command to one's 'service_notification_commands' like so:
#
#define contact {
#        contact_name                    rfrantz
#        alias                           Ryan Frantz
#        email                           rfrantz@etsy.com
#        use                             generic-contact
#        service_notification_commands   notify-service-by-email,dump-env
#}

LOGFILE="/tmp/nagios_env_$(date +%Y%m%d).log"
date >> $LOGFILE
env >> $LOGFILE
