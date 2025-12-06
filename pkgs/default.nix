{
  config,
  pkgs,
  lib,
  ...
}:
with lib; rec {
  sway-unwrapped = pkgs.sway-unwrapped.overrideAttrs (_: old: {
      patches = old.patches ++ [
        ./bigger-sway-drop-region.patch
      ];
  });

  sway = pkgs.sway.override {
    sway-unwrapped = sway-unwrapped;
    dbusSupport = false;
    enableXWayland = true;
    isNixOS = true;
    withBaseWrapper = true;
    withGtkWrapper = true;
    extraSessionCommands = ''
      export XDG_CURRENT_DESKTOP="sway:GNOME"
    '';
  };

  start-sway-gnome-session = pkgs.replaceVarsWith {
    src = ./start-sway-gnome-session;
    isExecutable = true;
    replacements = {
        inherit (pkgs) bash systemd;
        gnomeSession = pkgs.gnome-session;
    };
  };

  confirm-sway-gnome-session = pkgs.replaceVarsWith {
    src = ./confirm-sway-gnome-session;
    isExecutable = true;
    replacements = {
        inherit (pkgs) bash dbus systemd;
    };
  };

  wayland-session = pkgs.replaceVarsWith {
    src = ./wayland-sessions/sway-gnome.desktop;
    replacements = {
        startSwayGnomeSession = start-sway-gnome-session;
    };
  };

  mako-sway-gnome-service = pkgs.replaceVarsWith {
    src = "${./systemd/user}/mako@sway-gnome.service";
    replacements = {
        inherit (pkgs) mako;
    };
  };

  sway-launcher = pkgs.replaceVarsWith {
    src = ./sway-launcher;
    isExecutable = true;
    replacements = {
        inherit sway;
        inherit (pkgs) bash;
    };
  };

  sway-service = pkgs.replaceVarsWith {
    src = ./systemd/user/sway.service;
    replacements = {
        swayLauncher = sway-launcher;
    };
  };

  sway-gnome-desktop = pkgs.stdenv.mkDerivation {
    pname = "sway-gnome-desktop";
    version = "0.2.0";
    builder = pkgs.writeScript "builder.sh" ''
      source $stdenv/setup

      mkdir -p $out/share/wayland-sessions
      cp ${wayland-session} $out/share/wayland-sessions/sway-gnome.desktop

      mkdir -p $out/share/gnome-session/sessions
      cp ${./gnome-session/sessions/sway-gnome.session} \
        $out/share/gnome-session/sessions/sway-gnome.session

      mkdir -p $out/lib/systemd/user
      cp ${mako-sway-gnome-service} \
         $out/lib/systemd/user/mako@sway-gnome.service
      cp "${./systemd/user}/xdg-autostart-sway-gnome.target" \
         $out/lib/systemd/user/xdg-autostart-sway-gnome.target
      cp "${./systemd/user}/sway-gnome-session-basic-services.target" \
         $out/lib/systemd/user/sway-gnome-session-basic-services.target
      cp ${sway-service} $out/lib/systemd/user/sway.service
      mkdir -p $out/lib/systemd/user/gnome-session@sway-gnome.target.d
      cp ${./systemd/user}/gnome-session@sway-gnome.target.d/session.conf \
         $out/lib/systemd/user/gnome-session@sway-gnome.target.d/session.conf

      #mkdir -p $out/lib/systemd/user/gnome-session-manager@.service.d
      #cp ${gnome-session-manager-overrides} $out/lib/systemd/user/gnome-session-manager@.service.d/overrides.conf
    '';
    passthru = {
      providedSessions = ["sway-gnome"];
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

  waybarRev = "161367d9617673a4ef9caf8299411dc5153464d1";
  latestWaybar = (builtins.getFlake ("github:Alexays/Waybar/" + waybarRev)).packages.${pkgs.system}.default;

  gnome-session-manager-overrides = pkgs.writeTextFile {
    name = "overrides.conf";
    text = ''
      [Service]
      ExecStart=
      ExecStart=${pkgs.gnome-session}/bin/gnome-session --session=%i --debug --failsafe
    '';
  };
}
