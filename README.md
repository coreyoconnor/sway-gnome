# sway-gnome

[![License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](http://choosealicense.com/licenses/mit/)

--------------------------------------------------------------------------------

Allows you to use [Sway](https://github.com/swaywm/sway), a tiling window manager, with GNOME 3 session
infrastructure on NixOS.

## Work in progress

## What this enables

A limited combination of sway and gnome. This creates a custom gnome session that starts most
gnome services along with the sway window manager.

Stuff that kinda works:

 * flatpack in gnome software
 * keyring integration

The `gnome-control-center`, `Settings`, largely works as expected:

 * account settings
 * power management Settings
 * printer settings
 * sound settings
 * network settings
 * bluetooth settings
 * default apps settings
 * search settings

 These settings immediately crash will result in `Settings` unable to start again:

* multitasking settings

Use dconf editor to remove the last panel setting from gnome-control-center if `gnome-control-center` does not
start up after a crash.

## includes

 * `xdg-desktop-portal` - desktop integration for Flatpak and Snap
 * swayidle - for idle management
 * swaylock - for screen lock

# Installation

1. import as a nixos module:

EG: https://github.com/coreyoconnor/home-hive/blob/main/modules/default.nix#L25

2. You must add `include /etc/sway/config.d/*` to your sway config

Use the `nixos-25.05` branch for NixOS 25.05.

# Related Projects

 * [sway-services](https://github.com/xdbob/sway-services) provides a minimal sway / systemd integration with no GNOME services
 * https://gitlab.gnome.org/World/Phosh/phosh/-/blob/main/data/meson.build
 * https://github.com/alebastr/sway-systemd

# References

- https://github.com/emersion/xdg-desktop-portal-wlr/wiki/%22It-doesn't-work%22-Troubleshooting-Checklist
- https://github.com/emersion/xdg-desktop-portal-wlr/wiki/systemd-user-services,-pam,-and-environment-variables
- https://gitlab.gnome.org/GNOME/gnome-software/-/merge_requests/2309




