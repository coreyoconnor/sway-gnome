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
    fonts.packages = with pkgs; [
      cantarell-fonts
      dejavu_fonts
      source-code-pro # Default monospace font in 3.32
      source-sans
    ];

    qt = {
      enable = mkDefault true;
      platformTheme = null; # qt5 and qt6 config expect this.
      style = null; # qt5 and qt6 config expect this.
    };

    environment = {
      systemPackages = with pkgs; [
        adwaita-qt
        adwaita-qt6
        libsForQt5.qt5ct
        qadwaitadecorations-qt6
        qt6Packages.qtwayland
        qt6Packages.qt6ct
      ];
    };

    services = {
    };
  };
}

