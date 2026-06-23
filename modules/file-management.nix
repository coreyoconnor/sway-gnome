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
    environment = {
      systemPackages = with pkgs; [
        file-roller
        xdg-utils
      ];
    };

    # google drive support in nautilus etc..
    services.gvfs = {
      package = pkgs.gvfs.override {
        gnomeSupport = true;
      };
    };
  };
}

