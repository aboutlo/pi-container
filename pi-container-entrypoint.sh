#!/bin/sh
set -e

if [ ! -f /root/.pi/agent/extensions/rtk.ts ] && [ -f /usr/local/share/pi/extensions/rtk.ts ]; then
  exec pi -e /usr/local/share/pi/extensions/rtk.ts "$@"
fi

exec pi "$@"
