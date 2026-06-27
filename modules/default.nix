{ flameshot,
  swayfx,
  waybar,
  sway-gnome-pkgs-src
}: {
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.sway-gnome;
  notExcluded = pkg: mkDefault (!(lib.elem pkg config.environment.gnome.excludePackages));
  sway-gnome-pkgs = import sway-gnome-pkgs-src {inherit config pkgs lib;};
in with sway-gnome-pkgs;
{
  imports = [
    ./clipboard-management.nix
    ./file-management.nix
    ./launcher.nix
    ./look.nix
    ./media-controls.nix
  ];
  options = {
    sway-gnome = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
      package = mkOption {
        type = types.package;
        default = swayfx.packages.${pkgs.stdenv.hostPlatform.system}.default;
      };
    };
  };

  config = mkIf cfg.enable {
    nixpkgs.overlays = [
      waybar.overlays.waybar
    ];

    environment = {
      etc = {
        "sway/config.d/sway-gnome.conf".source = pkgs.writeText "sway-gnome.conf" ''
          exec --no-startup-id ${confirm-sway-gnome-session}
        '';
      };

      systemPackages = with pkgs; [
        grim # screenshot functionality
        waybar
        phinger-cursors
        slurp # screenshot functionality
        swayidle
        swaylock
        sway-gnome-desktop
        awww
        wayland
        wlogout
        cfg.package
        flameshot.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };

    programs = {
      sway = {
        enable = true;
        package = null;
      };
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
        gdm = {
          enable = true;
          autoSuspend = false;
        };
        defaultSession = mkDefault "sway-gnome";
        sessionPackages = [sway-gnome-desktop];
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

    xdg.autostart.enable = true;

    xdg.portal = {
      config = {
        sway = {
          default = [
            "gtk"
          ];
          "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
          "org.freedesktop.impl.portal.Screenshot" = "wlr";
          "org.freedesktop.impl.portal.ScreenCast" = "wlr";
          "org.freedesktop.impl.portal.Inhibit" = "none";
          "org.freedesktop.impl.portal.Background" = "none";
          "org.freedesktop.impl.portal.GlobalShortcuts" = "gnome";
          "org.freedesktop.impl.portal.Clipboard" = "gnome";
          "org.freedesktop.impl.portal.InputCapture" = "gnome";
          "org.freedesktop.impl.portal.Usb" = "gnome";
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
