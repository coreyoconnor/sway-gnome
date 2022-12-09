# sway-gnome

[![License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](http://choosealicense.com/licenses/mit/)

--------------------------------------------------------------------------------

Allows you to use [Sway](https://github.com/swaywm/sway), a tiling window manager, with GNOME 3 Session
infrastructure on NixOS.

## Work in progress

## What this enables

TBD for gnome 40. Don't have the gnome setting daemons starting up correctly yet.

 * Keybindings for controlling brightness, Play/Pause, Next/Previous Track, Mute, Volume Up/Down. You can customize [sway/config.d/gnome](./sway/config.d/gnome) after installation
 * Desktop integration for Flatpak and Snap
 * Idle management  / Screen Lock
 * Automatic screen adjustment at sunrise / sunset
 * Privilege management
 * Keyring integration
 * Dynamic display configuration
 * Accessibility Settings
 * Color Management Settings
 * Date & Time Settings
 * Keyboard Settings
 * Power Management Settings
 * Printer Notifications
 * Enabling and Disabling Wireless Devidces (rfkill)
 * Screensaver Settings
 * Handle Sharing music, pictures and videos on the local network
 * Remote Login settings
 * Smartcard handling
 * Sound settings
 * Wacom tablet handling
 * WWAN handling for modems / SIM Cards
 * Display Server settings



# includes

 * brightnessctl - support keybindings for screen brightness control
 * network-manager-gnome - Network Manager control applet
 * pulseaudio-utils - support keybindings for volume control
 * playerctl - support binding media keys
 * xdg-desktop-portal - desktop integration for Flatpak and Snap
 * swayidle - for idle management
 * swaylock - for screen lock
 * redshift - for automatic screen dimming
 * policykit-1-gnome - privilege management
 * mako - lightweight Wayland
 * [kanshi](https://github.com/emersion/kanshi) - Dynamic display configuration for Wayland
 * gnome-keyring - manage SSH keys, PKCS11 and other secrets
 * gnome-session-bin - the gnome session binary itself
 * gnome-settings-daemon-common - provides GNOME settings services.

## Installation

## Related Projects

 * [sway-services](https://github.com/xdbob/sway-services) provides a minimal sway / systemd integration with no GNOME services
 * https://gitlab.gnome.org/World/Phosh/phosh/-/blob/main/data/meson.build
