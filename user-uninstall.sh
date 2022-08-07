#!/bin/sh

set -ex

USER_DESTDIR=/home/${USER}/.config

SYSTEMD_DIRS=\
sway-session.target.wants

SYSTEMD_FILES="\
gnome-keyring.service \
gnome-session-manager@sway-gnome.service \
kanshi.service \
mako.service \
polkit-gnome.service \
redshift.service \
sway.service \
sway-session.target \
"

for F in $SYSTEMD_DIRS ; do
    rm -rf ${USER_DESTDIR}/systemd/user/$DIRS
done

for F in $SYSTEMD_FILES ; do
    rm -f ${USER_DESTDIR}/systemd/user/$F
done

rm -f ${USER_DESTDIR}/sway/config.d/gnome
rm -f ${USER_DESTDIR}/sway/env
