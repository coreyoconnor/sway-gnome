#!/bin/sh

set -ex

rm -rf /usr/local/bin/start-sway-session
rm -rf /usr/local/bin/start-sway-gnome-session

PATH_SWAY_SESSION=/usr/share/wayland-sessions/sway-gnome.desktop

rm -f ${PATH_SWAY_SESSION}
