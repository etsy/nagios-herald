#!/bin/bash
# This script wraps around the `check_disk` command available in the nagios-plugins package.

WARN_THRES="10%"
CRIT_THRES="5%"
EXCLUDE_PATH=""
EXCLUDE_FS=""

# We can exclude directories...
EXCLUDE_OPTS=""
EXCLUDE_FS_OPTS=""

if [ -n "$EXCLUDE_PATH" ]
then
    EXCLUDE_OPTS="-x ${EXCLUDE_PATH}"
fi

if [ -n "$EXCLUDE_FS" ]
then
    EXCLUDE_FS_OPTS="-x ${EXCLUDE_FS}"
fi

# Call check_disk
/usr/local/nagios-plugins/check_disk -l -e -w $WARN_THRES -c $CRIT_THRES $EXCLUDE_OPTS $EXCLUDE_FS_OPTS

# Store the return code so we can exit with the right code even after doing other things. 
RETURN=$?

# Print the check's thresholds.
printf "\nTHRESHOLDS - WARNING:%s;CRITICAL:%s;\n\n" $WARN_THRES $CRIT_THRES
# Print the output of `df` for the 'additional details' section.
df -h

exit $RETURN
