{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.sway-gnome;
  notExcluded = pkg: mkDefault (!(lib.elem pkg config.environment.gnome.excludePackages));
  sway-gnome-pkgs = import ./pkgs {inherit config pkgs lib;};
in
  with sway-gnome-pkgs; {
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
            exec --no-startup-id ${confirm-sway-gnome-session}
          '';
        };

        systemPackages = with pkgs; [
          qt6Packages.qtwayland
          fuzzel # launcher
          file-roller
          grim # screenshot functionality
          helvum
          latestWaybar
          pavucontrol
          phinger-cursors
          libsForQt5.qt5ct
          qt6Packages.qt6ct
          slurp # screenshot functionality
          swayidle
          swaylock
          sway-gnome-desktop
          swww
          wayland
          wlogout
          wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
          xdg-utils
        ];
      };

      fonts.packages = with pkgs; [
        cantarell-fonts
        dejavu_fonts
        source-code-pro # Default monospace font in 3.32
        source-sans
      ];

      programs = {
        sway = {
          enable = true;
          package = null;
        };
      };

      qt = {
        enable = mkDefault true;
        platformTheme = mkDefault null; # qt5 and qt6 config expect this.
        style = mkDefault null; # qt5 and qt6 config expect this.
      };

      services = {
        dbus = {
          enable = true;
          packages = [pkgs.gcr];
        };

        gnome = {
          # all appear to work
          core-developer-tools.enable = mkDefault true;

          # most appear to work
          core-os-services.enable = true;
          gnome-remote-desktop.enable = mkForce false;

          # all appear to work
          core-apps.enable = true;

          # close enough
          core-shell.enable = true;

          # appears to work
          at-spi2-core.enable = true;

          # all appear to work
          games.enable = mkDefault true;

          glib-networking.enable = true;
          gnome-initial-setup.enable = false;
          sushi.enable = notExcluded pkgs.sushi;
        };

        libinput.enable = mkDefault true;

        udev.packages = with pkgs; [gnome-settings-daemon];

        desktopManager.gnome.enable = false;

        displayManager = {
          defaultSession = mkDefault "sway-gnome";
          sessionPackages = [sway-gnome-desktop];

          gdm = {
            enable = mkDefault true;
            wayland = true;
          };
        };

        xserver = {
          enable = true; # xwayland
        };

        pipewire = {
          enable = mkDefault true;
          alsa = {
            enable = mkDefault true;
            support32Bit = mkDefault true;
          };
          pulse.enable = mkDefault true;
          wireplumber.enable = mkDefault true;
        };
      };

      systemd = {
        packages = [sway-gnome-desktop];

        user.services = {
          polkit-gnome-authentication-agent-1 = {
            unitConfig = {
              Description = "polkit-gnome-authentication-agent-1";
              Wants = ["graphical-session.target"];
              WantedBy = ["graphical-session.target"];
              After = ["graphical-session.target"];
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

      xdg.portal = {
        config = {
          sway = {
            default = [
              "gtk"
            ];
            "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
            "org.freedesktop.impl.portal.Screenshot" = "wlr";
            "org.freedesktop.impl.portal.Inhibit" = "none";
            "org.freedesktop.impl.portal.Background" = "none";
            "org.freedesktop.impl.portal.Clipboard" = "none";
            "org.freedesktop.impl.portal.GlobalShortcuts" = "none";
            "org.freedesktop.impl.portal.InputCapture" = "none";
            "org.freedesktop.impl.portal.RemoteDesktop" = "none";
            "org.freedesktop.impl.portal.Usb" = "none";
            "org.freedesktop.impl.portal.Wallpaper" = "none";
          };
        };
        enable = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-gtk
        ];
        wlr.enable = true;
      };
    };
  }
