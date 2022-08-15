#!/bin/bash

set -ex

USER_DESTDIR=/home/${USER}/.config

GNOME_DIR=gnome-session/sessions

GNOME_FILES=$(cat <<EOF
sway-gnome.session
EOF
)

SWAY_DIR=sway

SWAY_CONFIGS=$(cat <<EOF
sway-gnome
EOF
)

SWAY_ENVS=$(cat <<EOF
env
EOF
)

SYSTEMD_DIR=systemd/user

SYSTEMD_WANTS_DIRS=$(cat <<EOF
gnome-session@sway-gnome.target.d
EOF
)

SYSTEMD_FILES=$(cat <<EOF
kanshi@sway-gnome.service
mako@sway-gnome.service
sway-gnome.target
sway.service
EOF
)


uninstall_gnome () {
    for F in $GNOME_FILES ; do
        rm -f ${USER_DEST_DIR}/${GNOME_DIR}/$F
    done
}

uninstall_sway () {
    for F in $SWAY_CONFIGS ; do
        rm -f ${USER_DESTDIR}/${SWAY_DIR}/config.d/$F
    done

    for F in $SWAY_ENVS ; do
        rm -f ${USER_DESTDIR}/${SWAY_DIR}/$F
    done
}

uninstall_systemd () {
    for D in $SYSTEMD_WANTS_DIRS ; do
        rm -rf ${USER_DESTDIR}/${SYSTEMD_DIR}/$D
    done

    for F in $SYSTEMD_FILES ; do
        rm -f ${USER_DESTDIR}/${SYSTEMD_DIR}/$F
    done
}

install_gnome() {
    install -d ${USER_DESTDIR}/${GNOME_DIR}

    for F in $GNOME_FILES ; do
        install -m0644 -D ${GNOME_DIR}/$F ${USER_DESTDIR}/${GNOME_DIR}/$F
    done
}

install_sway() {
    install -d ${USER_DESTDIR}/${SWAY_DIR}
    install -d ${USER_DESTDIR}/${SWAY_DIR}/config.d

    for F in $SWAY_CONFIGS ; do
        install -m0644 -D sway/config.d/$F ${USER_DESTDIR}/${SWAY_DIR}/config.d/$F
    done

    for F in $SWAY_ENVS ; do
        install -m0644 -D sway/$F ${USER_DESTDIR}/${SWAY_DIR}/$F
    done
}

install_systemd() {
    install -d ${USER_DESTDIR}/${SYSTEMD_DIR}

    for D in $SYSTEMD_WANTS_DIRS ; do
        install -d ${USER_DESTDIR}/${SYSTEMD_DIR}/$D
        cp --no-dereference systemd/user/$D/* \
           ${USER_DESTDIR}/${SYSTEMD_DIR}/$D/
    done

    for F in $SYSTEMD_FILES ; do
        install -m0644 -D systemd/user/$F ${USER_DESTDIR}/${SYSTEMD_DIR}/$F
    done
}

case $(basename $0) in
    user-install.sh)
        echo installing gnome-session
        install_gnome

        echo installing sway configs
        install_sway

        echo installing systemd user configs
        install_systemd
        ;;

    user-uninstall.sh)
        echo uninstalling gnome-session
        uninstall_gnome

        echo uninstalling sway configs
        uninstall_sway

        echo uninstalling systemd user configs
        uninstall_systemd
        ;;
esac
