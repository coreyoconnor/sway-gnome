#!/bin/sh

set -ex

install -m0755 -D start-sway-session /usr/local/bin/start-sway-session
install -m0755 -D start-sway-gnome-session /usr/local/bin/start-sway-gnome-session

PATH_SWAY_SESSION=/usr/share/wayland-sessions/sway-gnome.desktop
install -m0644 -D wayland-sessions/sway-gnome.desktop ${PATH_SWAY_SESSION}
