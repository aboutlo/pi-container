#!/bin/sh
set -e

if [ -d /host-pi ]; then
  rm -rf /root/.pi
  mkdir -p /root/.pi
  tar -C /host-pi \
    --exclude='./agent/bin' \
    --exclude='./agent/sessions' \
    --exclude='./agent/npm' \
    --exclude='./agent/git' \
    --exclude='./agent/settings.json.lock' \
    --exclude='./agent/auth.json.lock' \
    -cf - . | tar -C /root/.pi -xf -

  mkdir -p /root/.pi/agent
  if [ -d /host-pi/agent/npm ]; then
    ln -s /host-pi/agent/npm /root/.pi/agent/npm
  fi
  if [ -d /host-pi/agent/git ]; then
    ln -s /host-pi/agent/git /root/.pi/agent/git
  fi
fi

if [ ! -f /root/.pi/agent/extensions/rtk.ts ] && [ -f /usr/local/share/pi/extensions/rtk.ts ]; then
  exec pi -e /usr/local/share/pi/extensions/rtk.ts "$@"
fi

exec pi "$@"
