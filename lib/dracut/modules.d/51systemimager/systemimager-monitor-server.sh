#!/bin/bash
#
# "SystemImager"
#
#  Copyright (C) 1999-2017 Brian Elliott Finley <brian@thefinleys.com>
#
#  $Id$
#  vi: set filetype=sh et ts=4:
#
#  Code written by Olivier LAHAYE.
#
# This file will start the si_monitor server that will let si_monitortk to
# remotely gather the imaging text console.

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh
type send_monitor_msg >/dev/null 2>&1 || . /lib/systemimager-lib.sh

logdebug "==== systemimager-monitor-server ===="

. /tmp/variables.txt

if [ ! -z "$MONITOR_SERVER" ]; then
    if test -f /tmp/si_monitor.log
    then
        mv -f /tmp/si_monitor.log /tmp/si_monitor_pre.log
    fi
    # 1st, load previous messages in log file.
    if test ! -f /tmp/si_monitor.log
    then
        if command -v journalctl >/dev/null 2>/dev/null
        then
            journalctl -ab --no-pager -o short-monotonic >/tmp/si_monitor.log
        else
            dmesg >/tmp/si_monitor.log
        fi
    fi
    if test -f /tmp/si_monitor_pre.log
    then
        cat /tmp/si_monitor_pre.log >> /tmp/si_monitor.log
        rm -f /tmp/si_monitor_pre.log
    fi

    # Then, Send initialization status.
    send_monitor_msg "status=0:first_timestamp=on:speed=0"
    loginfo "Monitoring initialized."
    # Start client log gathering server: for each connection
    # to the local client on port 8181 the full log is sent
    # to the requestor. -AR-
    if [ "x$MONITOR_CONSOLE" = "xy" ]; then
        MONITOR_CONSOLE=yes
    fi
    if [ "x$MONITOR_CONSOLE" = "xyes" ]; then
        if [ -z $MONITOR_PORT ]; then
            MONITOR_PORT=8181
        fi
        while :
        do
            # OL: BUG: Maybe we need to differentiate MONITOR_PORT on server
            # and CONSOLE_PORT on client being imager.
            ncat -p $MONITOR_PORT -l < /tmp/si_monitor.log || exit 1
        done &
	MONITOR_PID=$!
	echo $MONITOR_PID > /run/systemimager/si_monitor.pid
        loginfo "Logs monitor forwarding task started: PID=$MONITOR_PID ."
    fi
    loginfo "si monitor started"
fi
