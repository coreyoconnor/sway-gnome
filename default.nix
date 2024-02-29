{ config, pkgs, lib, ...}:
with lib;
let
  cfg = config.sway-gnome;
  notExcluded = pkg: mkDefault (!(lib.elem pkg config.environment.gnome.excludePackages));
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
      export XDG_CURRENT_DESKTOP=GNOME
    '';
  };

  sway-launcher = pkgs.writeScript "sway-launcher.sh" ''
    #!${pkgs.bash}/bin/bash

    source /etc/profile

    export MOZ_ENABLE_WAYLAND="1"
    export QT_QPA_PLATFORM="wayland;xcb"
    #export SDL_VIDEODRIVER=wayland
    export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
    export GTK_USE_PORTAL=1
    export NIXOS_XDG_OPEN_USE_PORTAL=1
    export GTK_THEME=Adwaita:dark
    export GNOME_SESSION_DEBUG=1
    # Fix for some Java AWT applications (e.g. Android Studio),
    # use this if they aren't displayed properly:
    export _JAVA_AWT_WM_NONREPARENTING=1
    export XDG_CURRENT_DESKTOP=GNOME
    export XDG_SESSION_TYPE=wayland
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
  # Prioritize nautilus by default when opening directories
  mimeAppsList = pkgs.writeTextFile {
    name = "gnome-mimeapps";
    destination = "/share/applications/mimeapps.list";
    text = ''
      [Default Applications]
      inode/directory=nautilus.desktop;org.gnome.Nautilus.desktop
    '';
  };

  waybarRev = "4d076a71f7f3dde877c436b171599422cf8b1afa";
  latestWaybar = (builtins.getFlake ("github:Alexays/Waybar/" + waybarRev)).packages.${pkgs.system}.default;
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
            "/share/nautilus-python/extensions"
          ];

          # Let nautilus find extensions
          # TODO: Create nautilus-with-extensions package
          sessionVariables.NAUTILUS_4_EXTENSION_DIR = "${config.system.path}/lib/nautilus/extensions-4";

          # Override default mimeapps for nautilus
          sessionVariables.XDG_DATA_DIRS = [ "${mimeAppsList}/share" ];

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
            packages = [ pkgs.gcr ];
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

          system-config-printer.enable = (mkIf config.services.printing.enable (mkDefault true));

          udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];

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
              sessionPackages = [ sway-gnome-desktop ];
            };
            libinput.enable = mkDefault true;
            updateDbusEnvironment = true;
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

        xdg.icons.enable = true;
        xdg.mime.enable = true;

        xdg.portal = {
          config = {
            GNOME = {
              default = [ "wlr" "gtk" ];
              "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
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
