{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.sway-gnome;
  notExcluded = pkg: mkDefault (!(lib.elem pkg config.environment.gnome.excludePackages));
  sway-gnome-pkgs = import ./pkgs { inherit config pkgs lib; };
in with sway-gnome-pkgs;
{
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
        "/share/nautilus-python/extensions"
      ];

      # Let nautilus find extensions
      # TODO: Create nautilus-with-extensions package
      sessionVariables.NAUTILUS_4_EXTENSION_DIR = "${config.system.path}/lib/nautilus/extensions-4";

      # Override default mimeapps for nautilus
      sessionVariables.XDG_DATA_DIRS = ["${mimeAppsList}/share"];

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
        latestWaybar
        wayland
        wlogout
        wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
        xdg-user-dirs
        xdg-utils
      ];
    };

    fonts.packages = with pkgs; [
      cantarell-fonts
      dejavu_fonts
      source-code-pro # Default monospace font in 3.32
      source-sans
    ];

    networking.networkmanager.enable = mkDefault true;

    programs = {
      evince.enable = notExcluded pkgs.gnome.evince;
      file-roller.enable = notExcluded pkgs.gnome.file-roller;
      geary.enable = notExcluded pkgs.gnome.geary;
      gnome-disks.enable = notExcluded pkgs.gnome.gnome-disk-utility;
      seahorse.enable = notExcluded pkgs.gnome.seahorse;
    };

    qt = {
      enable = mkDefault true;
      platformTheme = mkDefault "gnome";
      style = mkDefault "adwaita-dark";
    };

    security = {
      pam.services.swaylock = {};
      polkit.enable = true;
    };

    services = {
      accounts-daemon.enable = true;
      avahi.enable = mkDefault true;

      dbus = {
        enable = true;
        packages = [pkgs.gcr];
      };

      gnome = {
        # core-developer-tools.enable = true;
        core-os-services.enable = false;
        core-utilities.enable = true;
        games.enable = true;

        glib-networking.enable = true;
        gnome-initial-setup.enable = false;
        gnome-keyring.enable = true;
        gnome-online-accounts.enable = mkDefault true;
        gnome-online-miners.enable = true;
        gnome-settings-daemon.enable = true;
        sushi.enable = notExcluded pkgs.gnome.sushi;
        tracker-miners.enable = mkDefault true;
        tracker.enable = mkDefault true;
      };

      gvfs.enable = true;

      hardware.bolt.enable = mkDefault true;

      power-profiles-daemon.enable = mkDefault true;

      system-config-printer.enable = mkIf config.services.printing.enable (mkDefault true);

      udev.packages = with pkgs; [gnome.gnome-settings-daemon];

      udisks2.enable = true;

      upower.enable = config.powerManagement.enable;

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
          sessionPackages = [sway-gnome-desktop];
        };
        libinput.enable = mkDefault true;
        updateDbusEnvironment = true;
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

    xdg.icons.enable = true;
    xdg.mime.enable = true;

    xdg.portal = {
      config = {
        GNOME = {
          default = ["wlr" "gtk"];
          "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
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
