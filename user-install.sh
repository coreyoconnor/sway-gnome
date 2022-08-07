#!/bin/sh

set -ex

USER_DESTDIR=/home/${USER}/.config

install -d ${USER_DESTDIR}/systemd/user/sway-session.target.wants/

install -m0644 -D systemd/user/*.service ${USER_DESTDIR}/systemd/user/
install -m0644 -D systemd/user/sway-session.target ${USER_DESTDIR}/systemd/user/
cp --no-dereference systemd/user/sway-session.target.wants/* ${USER_DESTDIR}/systemd/user/sway-session.target.wants/

install -d ${USER_DESTDIR}/sway/config.d
install -m0644 -D sway/config.d/* ${USER_DESTDIR}/sway/config.d/
install -m0644 -D sway/env ${USER_DESTDIR}/sway/
