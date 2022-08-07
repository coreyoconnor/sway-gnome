#!/bin/sh

set -ex

PATH_SWAY_SERVICE=/usr/bin/sway-service
PATH_SWAY_SESSION=/usr/share/wayland-sessions/sway-systemd.desktop

rm -f ${PATH_SWAY_SERVICE}
rm -f ${PATH_SWAY_SESSION}
