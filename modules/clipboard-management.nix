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
        wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
      ];
    };
  };
}
