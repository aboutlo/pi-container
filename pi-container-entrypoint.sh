#!/bin/sh
set -e

if [ -d /host-pi ]; then
  rm -rf /root/.pi
  mkdir -p /root/.pi
  tar -C /host-pi \
    --exclude='./agent/bin' \
    --exclude='./agent/sessions' \
    --exclude='./agent/settings.json.lock' \
    --exclude='./agent/auth.json.lock' \
    -cf - . | tar -C /root/.pi -xf -
fi

if [ ! -f /root/.pi/agent/extensions/rtk.ts ] && [ -f /usr/local/share/pi/extensions/rtk.ts ]; then
  exec pi -e /usr/local/share/pi/extensions/rtk.ts "$@"
fi

exec pi "$@"
