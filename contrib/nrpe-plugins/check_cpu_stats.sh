#!/bin/bash
# ========================================================================================
# CPU Utilization Statistics plugin for Nagios 
#
# Written by    : Steve Bosek
# Release   : 2.1
# Creation date : 8 September 2007
# Revision date : 28 Februar 2008
# Package       : DTB Nagios Plugin
# Description   : Nagios plugin (script) to check cpu utilization statistics.
#       This script has been designed and written on Unix plateform (Linux, Aix, Solaris), 
#       requiring iostat as external program. The locations of these can easily 
#       be changed by editing the variables $IOSTAT at the top of the script. 
#       The script is used to query 4 of the key cpu statistics (user,system,iowait,idle)
#       at the same time. Note though that there is only one set of warning 
#       and critical values for iowait percent.
#
# Usage         : ./check_cpu_stats.sh [-w <warn>] [-c <crit] ( [ -i <intervals in second> ] [ -n <report number> ]) 
# ----------------------------------------------------------------------------------------
#
# TODO:  Support for HP-UX
#             
#
# ========================================================================================
#
# HISTORY :
#     Release   |     Date  |    Authors    |   Description
# --------------+---------------+---------------+------------------------------------------
#   2.0 |    16.02.08   |  Steve Bosek  | Solaris support and new parameters 
#               |       |               | New Parameters : - iostat seconds intervals 
#               |               |               |              - iostat report number
#  2.1 |  08.06.08 | Steve Bosek | Bug perfdata and convert comma in point for Linux result
# -----------------------------------------------------------------------------------------
#   
# =========================================================================================

# Paths to commands used in this script.  These may have to be modified to match your system setup.

IOSTAT=/usr/bin/iostat

# Nagios return codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

# Plugin parameters value if not define
WARNING_THRESHOLD=${WARNING_THRESHOLD:="30"}
CRITICAL_THRESHOLD=${CRITICAL_THRESHOLD:="100"}
INTERVAL_SEC=${INTERVAL_SEC:="3"}
NUM_REPORT=${NUM_REPORT:="2"}

# Plugin variable description
PROGNAME=$(basename $0)
RELEASE="Revision 2.1"
AUTHOR="(c) 2008 Steve Bosek (steve.bosek@gmail.com)"

if [ ! -x $IOSTAT ]; then
    echo "UNKNOWN: iostat not found or is not executable by the nagios user."
    exit $STATE_UNKNOWN
fi

# Functions plugin usage
print_release() {
    echo "$RELEASE $AUTHOR"
}

print_usage() {
    echo ""
    echo "$PROGNAME $RELEASE - CPU Utilization check script for Nagios"
    echo ""
    echo "Usage: check_cpu_stats.sh -w -c -wi -ci (-i -n)"
    echo ""
    echo "  -w  Warning level in % for cpu iowait"
    echo "  -c  Crical level in % for cpu iowait"
    echo "  -wi Warn if cpu idle is less than x"
    echo "  -ci Critical is CPU idle is less than x"
    echo "  -i  Interval in seconds for iostat (default : 3)"
    echo "  -n  Number report for iostat (default : 2)"
    echo "  -h  Show this page"
    echo ""
    echo "Usage: $PROGNAME"
    echo "Usage: $PROGNAME --help"
    echo ""
}

print_help() {
    print_usage
    echo ""
    echo "This plugin will check cpu utilization (user,system,iowait,idle in %)"
    echo ""
    exit 0
}

# Parse parameters
while [ $# -gt 0 ]; do
    case "$1" in
        -h | --help)
            print_help
            exit $STATE_OK
            ;;
        -v | --version)
                print_release
                exit $STATE_OK
                ;;
        -w | --warning)
                shift
                WARNING_THRESHOLD=$1
                ;;
        -c | --critical)
               shift
                CRITICAL_THRESHOLD=$1
                ;;
    -wi | --warn-idle)
        shift
        WARN_IDLE=$1
        ;;
        -ci | --critical-idle)
                shift
                CRIT_IDLE=$1
                ;;
        -i | --interval)
               shift
               INTERVAL_SEC=$1
                ;;
        -n | --number)
               shift
               NUM_REPORT=$1
                ;;        
        *)  echo "Unknown argument: $1"
            print_usage
            exit $STATE_UNKNOWN
            ;;
        esac
shift
done

# CPU Utilization Statistics Unix Plateform ( Linux,AIX,Solaris are supported )
case `uname` in
       Linux ) CPU_REPORT=`iostat -c $INTERVAL_SEC $NUM_REPORT|tail -2|head -n 1| tr -s " " " " `
               CPU_USER=`echo $CPU_REPORT | cut -d " " -f 1 `
               CPU_SYSTEM=`echo $CPU_REPORT | cut -d " " -f 3 `
               CPU_IOWAIT=`echo $CPU_REPORT | cut -d " " -f 4 `
               CPU_IO=`echo $CPU_IOWAIT | sed s/\\\./""/`
               CPU_IDLE=`echo $CPU_REPORT | cut -d " " -f 6`
               CPU_IDL=`echo $CPU_IDLE | sed s/\\\./""/`
            ;;
    *)      echo "UNKNOWN: `uname` not yet supported by this plugin. Coming soon !"
            exit $STATE_UNKNOWN 
        ;;
    esac

WARNING_THRESH=$(( $WARNING_THRESHOLD * 100 ))
CRIT_THRESH=$(( $CRITICAL_THRESHOLD * 100 ))
WARN_IDLE_THRESH=$(( $WARN_IDLE * 100 ))
CRIT_IDLE_THRESH=$(( $CRIT_IDLE * 100 ))

OUTPUT="user=${CPU_USER}% system=${CPU_SYSTEM}% iowait=${CPU_IOWAIT}% idle=${CPU_IDLE}% |  user = ${CPU_USER}, system = ${CPU_SYSTEM}, iowait = ${CPU_IOWAIT}, idle = ${CPU_IDLE}  "

find_top_five_procs_by_cpu() {
    echo "TOP 5 PROCESSES BY CPU:"
    ps -eo %cpu,cputime,user,pid,args --sort -%cpu | head -n 6 | awk '{command = substr($0, index($0,$5)); printf "%5s %12s %12s %6s %s\n", $1, $2, $3, $4, command}'
}

# Return
if [ $CPU_IO -ge $CRIT_THRESH ]; then
    echo "CRITICAL CPU iowait is > ${CRITICAL_THRESHOLD}%: ${OUTPUT}"
    find_top_five_procs_by_cpu
    exit $STATE_CRITICAL
elif [ $CPU_IO -ge $WARNING_THRESH ]; then
    echo "WARNING CPU iowait is > ${WARNING_THRESHOLD}%: ${OUTPUT}"
    find_top_five_procs_by_cpu
    exit $STATE_WARNING
elif [ $CPU_IDL -le $CRIT_IDLE_THRESH ]; then
    echo "CRITICAL CPU idle is < ${CRIT_IDLE}%: ${OUTPUT}"
    find_top_five_procs_by_cpu
    exit $STATE_CRITICAL
elif [ $CPU_IDL -le $WARN_IDLE_THRESH ]; then
    echo "WARNING CPU idle is < ${WARN_IDLE}%: ${OUTPUT}"
    find_top_five_procs_by_cpu
    exit $STATE_WARNING
else
    echo "OK: ${OUTPUT}"
    exit $STATE_OK
fi

