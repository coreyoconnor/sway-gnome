{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.sway-gnome;
in {
  config = mkIf cfg.enable {
    xdg.autostart.enable = true;

    xdg.portal = {
      config = {
        sway = {
          default = [
            "gtk"
          ];
          "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
          "org.freedesktop.impl.portal.FileChooser" = "gnome";
          "org.freedesktop.impl.portal.Screenshot" = "wlr";
          "org.freedesktop.impl.portal.ScreenCast" = "wlr";
          "org.freedesktop.impl.portal.Inhibit" = "none";
          "org.freedesktop.impl.portal.Background" = "none";
          "org.freedesktop.impl.portal.GlobalShortcuts" = "none";
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
