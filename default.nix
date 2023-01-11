{ pkgs ? import <nixpkgs> { }
, lib ? pkgs.lib
}:
with lib;
let
  start-sway-session = pkgs.substituteAll {
    src = ./start-sway-session;
    isExecutable = true;
    inherit (pkgs) bash systemd;
  };

  start-sway-gnome-session = pkgs.substituteAll {
    src = ./start-sway-gnome-session;
    isExecutable = true;
    inherit (pkgs) bash dbus systemd;
    gnomeSession = pkgs.gnome.gnome-session;
  };

  desktop-session = pkgs.substituteAll {
    src = ./wayland-sessions/sway-gnome.desktop;
    startSwaySession = start-sway-session;
  };

  mako-sway-gnome-service = pkgs.substituteAll {
    src = "${./systemd/user}/mako@sway-gnome.service";
    inherit (pkgs) mako;
  };

  sway = pkgs.sway.override {
    dbusSupport = false;
    enableXWayland = true;
    isNixOS = true;
    withBaseWrapper = false;
    withGtkWrapper = true;
  };

  sway-launcher = pkgs.writeScript "sway-launcher.sh" ''
    #!${pkgs.bash}/bin/bash

    export MOZ_ENABLE_WAYLAND="1"
    export QT_QPA_PLATFORM=wayland-egl
    export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
    # Fix for some Java AWT applications (e.g. Android Studio),
    # use this if they aren't displayed properly:
    export _JAVA_AWT_WM_NONREPARENTING=1
    export PATH=$PATH:/run/current-system/sw/bin

    exec ${sway}/bin/sway
  '';

  sway-service = pkgs.substituteAll {
    src = "${./systemd/user}/sway.service";
    swayLauncher = sway-launcher;
  };

  sway-gnome-desktop = pkgs.stdenv.mkDerivation {
    pname = "sway-gnome-desktop";
    version = "0.1.0";
    builder = pkgs.writeScript "builder.sh" ''
      source $stdenv/setup

      mkdir -p $out/share/wayland-sessions
      cp ${desktop-session} $out/share/wayland-sessions/sway-gnome.desktop

      mkdir -p $out/lib/systemd/user
      cp ${./systemd/user}/sway-gnome.target $out/lib/systemd/user/sway-gnome.target
      cp ${mako-sway-gnome-service} \
         $out/lib/systemd/user/mako@sway-gnome.service
      cp ${sway-service} $out/lib/systemd/user/sway.service
      mkdir -p $out/lib/systemd/user/gnome-session@sway-gnome.target.d
      cp ${./systemd/user}/gnome-session@sway-gnome.target.d/sway-gnome.session.conf \
         $out/lib/systemd/user/gnome-session@sway-gnome.target.d/sway-gnome.session.conf
    '';
    passthru = {
      providedSessions = [ "sway-gnome" ];
    };
  };
in {
  pkgs = {
    inherit desktop-session
      start-sway-session
      start-sway-gnome-session
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
              exec ${start-sway-gnome-session}
            '';
          };
          systemPackages = with pkgs; [ qt6Packages.qtwayland ];
        };

        security.pam.services.swaylock = {};

        services = {
          gnome = {
            core-developer-tools.enable = true;

            core-utilities.enable = true;
            gnome-initial-setup.enable = false;
            gnome-remote-desktop.enable = false;
          };

          xserver = {
            desktopManager.gnome.enable = true;
            displayManager = {
              defaultSession = mkDefault "sway-gnome";
              sessionPackages = [ sway-gnome-desktop ];
            };
          };
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
      };
    };
}
