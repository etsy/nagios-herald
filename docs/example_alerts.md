# Example Alerts

To demonstrate how ``nagios-herald`` can format alerts to be more legible and useful, see below for some example alerts without context (before ``nagios-herald``) and **with** context (**after** ``nagios-herald``).

## CPU Alert

### No Context

This is a basic CPU alert informing the operator that *something* is wrong with a server's overall processor utilization.

![cpu_no_context](/docs/images/cpu_no_context.png)

### With Context

The CPU check has been updated to inform the operator of which threshold has been exceeded and lists the top 5 processes by processor utilization and ``nagios-herald`` formatted the content to make it more legible.

![cpu_with_context](/docs/images/cpu_with_context.png)

## Disk Space Alert

Among most operators, disk space alerts probably garner the most disdain for their lack of utility and frequency of delivery.

### No Context

It's easy to understand why disk space alerts are perceived to be useless given the following example.

![disk_space_no_context](/docs/images/disk_space_no_context.png)

### With Context

Now, imagine how much more useful it would be if the check output the results of ``df`` and ``nagios-herald`` could use that information to provide context.  In the example below, ``nagios-herald`` was used to add a **stack bar** to indicate which volume exceeded the threshold, add a **Ganglia graph** of disk utilization for the past 24 hours, **highlight** the relevant volume in the ``df`` output, and even inform the operator of the **number of times in the last week** that the alert fired.

![disk_space_with_context](/docs/images/disk_space_with_context.png)

## Memory Alert

### No Context

Memory alerts that simply inform the operator that some threshold have been exceeded aren't very helpful.

![memory_high_no_context](/docs/images/memory_high_no_context.png)

### With Context

The first thing most operators do is run ``top`` to understand what processes are running, sorted by memory usage.  In the example below, the check was updated to output the top 5 processes by memory utilization and ``nagios-herald`` formatted the output for legibility.

![memory_high_with_context](/docs/images/memory_high_with_context.png)

