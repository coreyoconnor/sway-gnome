{ pkgs ? import <nixpkgs> { }
, lib ? pkgs.lib
}:
with lib;
let
  desktop-name = "GNOME";
  start-wayland-session = pkgs.substituteAll {
    src = ./start-wayland-session;
    isExecutable = true;
    inherit (pkgs) bash systemd;
  };

  start-gnome-session = pkgs.substituteAll {
    src = ./start-gnome-session;
    isExecutable = true;
    inherit (pkgs) bash dbus systemd;
    gnomeSession = pkgs.gnome.gnome-session;
  };

  wayland-session = pkgs.substituteAll {
    src = ./wayland-sessions/sway-gnome.desktop;
    gnomeSession = pkgs.gnome.gnome-session;
    startWaylandSession = start-wayland-session;
  };

  mako-sway-gnome-service = pkgs.substituteAll {
    src = "${./systemd/user}/mako@sway-gnome.service";
    inherit (pkgs) mako;
  };

  sway = pkgs.sway.override {
    dbusSupport = true;
    enableXWayland = true;
    isNixOS = true;
    withBaseWrapper = true;
    withGtkWrapper = true;
    extraSessionCommands = ''
      export XDG_CURRENT_DESKTOP=${desktop-name}
    '';
  };

  sway-launcher = pkgs.writeScript "sway-launcher.sh" ''
    #!${pkgs.bash}/bin/bash

    source /etc/profile

    export MOZ_ENABLE_WAYLAND="1"
    export QT_QPA_PLATFORM="wayland;xcb"
    export SDL_VIDEODRIVER=wayland
    export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
    #export GTK_USE_PORTAL=1
    # export NIXOS_XDG_OPEN_USE_PORTAL=1
    export GNOME_SESSION_DEBUG=1
    # Fix for some Java AWT applications (e.g. Android Studio),
    # use this if they aren't displayed properly:
    export _JAVA_AWT_WM_NONREPARENTING=1
    export XDG_CURRENT_DESKTOP=${desktop-name}
    export XDG_SESSION_DESKTOP=${desktop-name}
    export XDG_SESSION_TYPE=wayland
    export DESKTOP_SESSION=${desktop-name}
    export GIO_EXTRA_MODULES=${pkgs.gvfs}/lib/gio/modules

    exec ${sway}/bin/sway
  '';

  gnome-session-manager-overrides = pkgs.writeTextFile {
    name = "overrides.conf";
    text = ''
      [Service]
      ExecStart=
      ExecStart=${pkgs.gnome.gnome-session}/bin/gnome-session --systemd-service --session=%i --debug --failsafe
    '';
  };

  sway-service = pkgs.substituteAll {
    src = ./systemd/user/sway.service;
    swayLauncher = sway-launcher;
  };

  sway-desktop = pkgs.substituteAll {
    src = ./desktop/sway.desktop;
    swayLauncher = sway-launcher;
  };

  sway-gnome-desktop = pkgs.stdenv.mkDerivation {
    pname = "sway-gnome-desktop";
    version = "0.1.0";
    builder = pkgs.writeScript "builder.sh" ''
      source $stdenv/setup

      mkdir -p $out/share/wayland-sessions
      cp ${wayland-session} $out/share/wayland-sessions/sway-gnome.desktop

      mkdir -p $out/lib/systemd/user
      cp ${./systemd/user}/sway-gnome.target $out/lib/systemd/user/sway-gnome.target
      cp ${mako-sway-gnome-service} \
         $out/lib/systemd/user/mako@sway-gnome.service
      cp ${sway-service} $out/lib/systemd/user/sway.service
      mkdir -p $out/lib/systemd/user/gnome-session@sway-gnome.target.d
      cp ${./systemd/user}/gnome-session@sway-gnome.target.d/session.conf \
         $out/lib/systemd/user/gnome-session@sway-gnome.target.d/session.conf

      mkdir -p $out/share/gnome-session/sessions
      cp ${./gnome-session/sessions/sway-gnome.session} $out/share/gnome-session/sessions/sway-gnome.session

      #mkdir -p $out/lib/systemd/user/gnome-session-manager@.service.d
      #cp ${gnome-session-manager-overrides} $out/lib/systemd/user/gnome-session-manager@.service.d/overrides.conf

      mkdir -p $out/share/applications
      cp ${sway-desktop} $out/share/applications/sway.desktop
    '';
    passthru = {
      providedSessions = [ "sway-gnome" ];
    };
  };
in {
  pkgs = {
    inherit wayland-session
      start-wayland-session
      start-gnome-session
      sway-launcher
      sway-gnome-desktop;
  };

  module = { config, pkgs, lib, ... }:
    let cfg = config.sway-gnome;
    in {
      options = {
        sway-gnome = {
          enable = mkOption {
            type = types.bool;
            default = false;
          };
        };
      };

      config = mkIf cfg.enable {
        environment = {
          etc = {
            "sway/config.d/sway-gnome.conf".source = pkgs.writeText "sway-gnome.conf" ''
              exec ${start-gnome-session}
            '';
          };

          pathsToLink = [
            "/share" # TODO: https://github.com/NixOS/nixpkgs/issues/47173
          ];

          systemPackages = with pkgs; [
            gnome.adwaita-icon-theme
            gnome.gnome-bluetooth
            gnome.gnome-color-manager
            gnome.gnome-control-center
            qt6Packages.qtwayland
            fuzzel # launcher
            glib # for gsettings
            grim # screjnshot functionality
            gtk3.out # for gtk-launch program
            helvum
            orca
            pavucontrol
            slurp # screenshot functionality
            sound-theme-freedesktop
            # sway
            swayidle
            swaylock
            sway-gnome-desktop
            swww
            waybar
            wayland
            wlogout
            wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
            xdg-user-dirs
            xdg-utils
          ];
        };

        networking.networkmanager.enable = mkDefault true;

        qt = {
          enable = mkDefault true;
          platformTheme = mkDefault "gnome";
          style = mkDefault "adwaita-dark";
        };

        security.pam.services.swaylock = {};

        services = {
          accounts-daemon.enable = true;

          dbus.enable = true;

          gnome = {
            # core-developer-tools.enable = true;
            core-os-services.enable = false;
            core-utilities.enable = true;
            games.enable = true;

            gnome-initial-setup.enable = false;
            gnome-keyring.enable = true;
            gnome-online-accounts.enable = mkDefault true;
            # gnome-online-miners.enable = true;
            # gnome-remote-desktop.enable = false;

            # tracker-miners.enable = mkDefault true;
            # tracker.enable = mkDefault true;
          };

          gvfs.enable = true;

          xfs.enable = false;

          xserver = {
            enable = true;
            desktopManager.gnome.enable = false;
            displayManager = {
              gdm = {
                enable = mkDefault true;
                wayland = true;
              };
              defaultSession = mkDefault "sway-gnome";
              sessionPackages = [ sway-gnome-desktop ];
            };
            libinput.enable = mkDefault true;
          };


          udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];

          udisks2.enable = true;

          upower.enable = config.powerManagement.enable;
        };

        systemd = {
          packages = [ sway-gnome-desktop ];

          user.services = {
            polkit-gnome-authentication-agent-1 = {
              unitConfig = {
                Description = "polkit-gnome-authentication-agent-1";
                Wants = [ "graphical-session.target" ];
                WantedBy = [ "graphical-session.target" ];
                After = [ "graphical-session.target" ];
              };

              serviceConfig = {
                Type = "simple";
                ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
                Restart = "on-failure";
                RestartSec = 1;
                TimeoutStopSec = 10;
              };
            };
          };
        };

        xdg.icons.enable = true;
        xdg.mime.enable = true;
        xdg.portal = {
          enable = true;
          extraPortals = [ pkgs.xdg-desktop-portal-wlr pkgs.xdg-desktop-portal-gtk ];
        };
      };
    };
}
