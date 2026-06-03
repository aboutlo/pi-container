#!/bin/sh
set -e

if [ ! -f /root/.pi/agent/extensions/rtk.ts ]; then
  if ! rtk init -g --agent pi --auto-patch >/dev/null 2>&1; then
    echo "warning: rtk Pi initialization failed; continuing without RTK hook setup" >&2
  fi
fi

exec pi "$@"
