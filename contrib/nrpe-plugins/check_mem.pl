#!/usr/bin/perl -w
# $Id: check_mem.pl 2 2002-02-28 06:42:51Z egalstad $

# check_mem.pl Copyright (C) 2000 Dan Larsson <dl@tyfon.net>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# you should have received a copy of the GNU General Public License
# along with this program (or with Nagios);  if not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA

# Tell Perl what we need to use
use strict;
use Getopt::Std;

use vars qw($opt_c $opt_f $opt_u $opt_w
            $free_memory $used_memory $total_memory $cached_memory
            $crit_level $warn_level
            %exit_codes @memlist
            $percent $fmt_pct $fmt_used $fmt_free $fmt_cached $fmt_slabs
            $verb_err $command_line $slabs_reclaimable);

# Predefined exit codes for Nagios
%exit_codes   = ('UNKNOWN' , 3,
                 'OK'      , 0,
                 'WARNING' , 1,
                 'CRITICAL', 2,);

# Turn this to 1 to see reason for parameter errors (if any)
$verb_err     = 1;

# This the unix command string that brings Perl the data
$command_line = `free |grep Mem|awk '{print \$2,\$3,\$4,\$7}'`;

chomp $command_line;
@memlist      = split(/ /, $command_line);

# Get the amount used by dentry_cache etc, as this counts as "free" too.
$slabs_reclaimable = `grep SReclaimable /proc/meminfo | awk '{print \$2}'`;
chomp $slabs_reclaimable;

# Time for calculations. Cached and the slabs reclaimable shouldn't count as "used" 
# because they can and will be used by the kernel if needs be (before swapping)
$cached_memory = $memlist[3];
$used_memory  = $memlist[1] - $cached_memory - $slabs_reclaimable;
$free_memory  = $memlist[2] + $cached_memory + $slabs_reclaimable;
$total_memory = $memlist[0];

# All our machines have over a GB of RAM. Stop this sillyness. 
$used_memory = $used_memory / 1024 / 1024;
$free_memory = $free_memory / 1024 / 1024;
$total_memory = $total_memory / 1024 / 1024;
$cached_memory = $cached_memory / 1024 / 1024;
$slabs_reclaimable = $slabs_reclaimable / 1024 / 1024;

# Some pretty formatting for output purposes. 
$fmt_free   = sprintf "%.3f", $free_memory;
$fmt_used   = sprintf "%.3f", $used_memory;
$fmt_cached = sprintf "%.3f", $cached_memory;
$fmt_slabs  = sprintf "%.3f", $slabs_reclaimable;

# Get the options
if ($#ARGV le 0)
{
  &usage;
}
else
{
  getopts('c:fuw:');
}

# Shortcircuit the switches
if (!$opt_w or $opt_w == 0 or !$opt_c or $opt_c == 0)
{
  print "*** You must define WARN and CRITICAL levels!" if ($verb_err);
  &usage;
}
elsif (!$opt_f and !$opt_u)
{
  print "*** You must select to monitor either USED or FREE memory!" if ($verb_err);
  &usage;
}

# Check if levels are sane
if ($opt_w <= $opt_c and $opt_f)
{
  print "*** WARN level must not be less than CRITICAL when checking FREE memory!" if ($verb_err);
  &usage;
}
elsif ($opt_w >= $opt_c and $opt_u)
{
  print "*** WARN level must not be greater than CRITICAL when checking USED memory!" if ($verb_err);
  &usage;
}

$warn_level   = $opt_w;
$crit_level   = $opt_c;

sub find_top_five_procs_by_mem {
  # Find the top 5 process by memory usage; sort by RSS in descending order.
  my @top_five_procs = qx/ps -eo %mem,rss,user,pid,args --sort -rss | head -n 6 | awk '{command = substr(\$0, index(\$0,\$5)); printf "%5s %12s %12s %6s %s\\n", \$1, \$2, \$3, \$4, command}'/;
  print 'TOP 5 PROCESSES BY MEMORY USAGE:\n';
  foreach my $line (@top_five_procs) {
    chomp $line;
    print $line . '\n';
  }
}

if ($opt_f)
{
  $percent    = $free_memory / $total_memory * 100;
  $fmt_pct    = sprintf "%.1f", $percent;
  if ($percent <= $crit_level)
  {
    print "Memory CRITICAL - $fmt_pct% free ($fmt_free GB total including $fmt_cached GB cached, $fmt_slabs GB reclaimable) \n";
    find_top_five_procs_by_mem();
    exit $exit_codes{'CRITICAL'};
  }
  elsif ($percent <= $warn_level)
  {
    print "Memory WARNING - $fmt_pct% free ($fmt_free GB total including $fmt_cached GB cached, $fmt_slabs GB reclaimable) \n";
    find_top_five_procs_by_mem();
    exit $exit_codes{'WARNING'};
  }
  else
  {
    print "Memory OK - $fmt_pct% free ($fmt_free GB total including $fmt_cached GB cached, $fmt_slabs GB reclaimable) \n";
    exit $exit_codes{'OK'};
  }
}
elsif ($opt_u)
{
  $percent    = $used_memory / $total_memory * 100;
  $fmt_pct    = sprintf "%.1f", $percent;
  if ($percent >= $crit_level)
  {
    print "Memory CRITICAL - $fmt_pct% used ($fmt_used GB total plus $fmt_cached GB cached, $fmt_slabs GB reclaimable)\n";
    find_top_five_procs_by_mem();
    exit $exit_codes{'CRITICAL'};
  }
  elsif ($percent >= $warn_level)
  {
    print "Memory WARNING - $fmt_pct% used ($fmt_used GB total plus $fmt_cached GB cached, $fmt_slabs GB reclaimable)\n";
    find_top_five_procs_by_mem();
    exit $exit_codes{'WARNING'};
  }
  else
  {
    print "Memory OK - $fmt_pct% used ($fmt_used GB total plus $fmt_cached GB cached, $fmt_slabs GB reclaimable)\n";
    exit $exit_codes{'OK'};
  }
}

# Show usage
sub usage()
{
  print "\ncheck_mem.pl v1.0 - Nagios Plugin\n\n";
  print "usage:\n";
  print " check_mem.pl -<f|u> -w <warnlevel> -c <critlevel>\n\n";
  print "options:\n";
  print " -f           Check FREE memory\n";
  print " -u           Check USED memory\n";
  print " -w PERCENT   Percent free/used when to warn\n";
  print " -c PERCENT   Percent free/used when critical\n";
  print "\nCopyright (C) 2000 Dan Larsson <dl\@tyfon.net>\n";
  print "check_mem.pl comes with absolutely NO WARRANTY either implied or explicit\n";
  print "This program is licensed under the terms of the\n";
  print "GNU General Public License (check source code for details)\n";
  exit $exit_codes{'UNKNOWN'}; 
}


