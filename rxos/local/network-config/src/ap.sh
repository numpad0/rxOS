#!/bin/sh
#
# Start, stop, and restart hostapd
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

ACTION="$1"
PIDFILE="/var/run/hostapd.pid"
CONF="/etc/hostapd.conf"
LOG="logger -st ap"

start() {
  if hostapd -B -P "$PIDFILE" "$CONF"; then
    $LOG "Started hostapd"
    return 0
  else
    $LOG "ERROR: Could not start hostapd"
    return 1
  fi
}

stop() {
  pid="$(cat "$PIDFILE")"
  [ -z "$pid" ] && return 0
  if kill "$pid"; then
    $LOG "Stopped hostapd"
    return 0
  else
    $LOG "ERROR: Could not stop hostapd"
    return 1
  fi
}

restart() {
  stop
  sleep 2
  start
}

help() {
  echo "Usage: $0 {start|stop|restart}"
}

"${ACTION:=help}"
exit $?
