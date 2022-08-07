#!/bin/sh

set -ex

PATH_SWAY_SERVICE=/usr/bin/sway-service
PATH_SWAY_SESSION=/usr/share/wayland-sessions/sway-systemd.desktop

install -m0644 -D wayland-sessions/sway-systemd.desktop ${PATH_SWAY_SESSION}
install -m0755 -D sway-service ${PATH_SWAY_SERVICE}
