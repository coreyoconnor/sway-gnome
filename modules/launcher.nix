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
  };
}

