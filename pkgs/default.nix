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
  start-wayland-session = pkgs.substituteAll {
    src = ./start-wayland-session;
    isExecutable = true;
    inherit (pkgs) bash systemd;
  };

  start-gnome-session = pkgs.substituteAll {
    src = ./start-gnome-session;
    isExecutable = true;
    inherit (pkgs) bash dbus systemd;
    gnomeSession = pkgs.gnome-session;
  };

  wayland-session = pkgs.substituteAll {
    src = ./wayland-sessions/sway-gnome.desktop;
    gnomeSession = pkgs.gnome-session;
    startWaylandSession = start-wayland-session;
  };

  mako-sway-gnome-service = pkgs.substituteAll {
    src = "${./systemd/user}/mako@sway-gnome.service";
    inherit (pkgs) mako;
  };

  sway-launcher = pkgs.writeScript "sway-launcher.sh" ''
    #!${pkgs.bash}/bin/bash

    source /etc/profile

    export MOZ_ENABLE_WAYLAND="1"
    export QT_QPA_PLATFORM="wayland;xcb"
    export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
    export GTK_USE_PORTAL=1
    export NIXOS_XDG_OPEN_USE_PORTAL=1
    export GNOME_SESSION_DEBUG=1
    # Fix for some Java AWT applications (e.g. Android Studio),
    # use this if they aren't displayed properly:
    export _JAVA_AWT_WM_NONREPARENTING=1
    export XDG_CURRENT_DESKTOP="sway:GNOME"
    export XDG_SESSION_DESKTOP=GNOME
    export XDG_SESSION_TYPE=wayland
    export GIO_EXTRA_MODULES=${pkgs.gvfs}/lib/gio/modules
    export XCURSOR_SIZE=48

    exec ${sway}/bin/sway
  '';

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

  waybarRev = "4d076a71f7f3dde877c436b171599422cf8b1afa";
  latestWaybar = (builtins.getFlake ("github:Alexays/Waybar/" + waybarRev)).packages.${pkgs.system}.default;

  gnome-session-manager-overrides = pkgs.writeTextFile {
    name = "overrides.conf";
    text = ''
      [Service]
      ExecStart=
      ExecStart=${pkgs.gnome-session}/bin/gnome-session --systemd-service --session=%i --debug --failsafe
    '';
  };
}
