# sway-gnome

[![License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](http://choosealicense.com/licenses/mit/)

--------------------------------------------------------------------------------

Allows you to use [Sway](https://github.com/swaywm/sway), a tiling window manager, with GNOME 3 Session
infrastructure on NixOS.

## Work in progress

## What this enables

TBD for gnome 40. Don't have the gnome setting daemons starting up correctly yet.

 * flatpack in gnome software
 * Keyring integration
 * Accessibility Settings
 * Color Management Settings
 * Date & Time Settings ?
 * Keyboard Settings
 * Power Management Settings
 * Printer Notifications
 * Sound settings

# includes

 * xdg-desktop-portal - desktop integration for Flatpak and Snap
 * swayidle - for idle management
 * swaylock - for screen lock

## Installation

import as a nixos module:

EG: https://github.com/coreyoconnor/nix_configs/blob/main/modules/default.nix#L3

## Related Projects

 * [sway-services](https://github.com/xdbob/sway-services) provides a minimal sway / systemd integration with no GNOME services
 * https://gitlab.gnome.org/World/Phosh/phosh/-/blob/main/data/meson.build
