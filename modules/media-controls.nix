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
        pavucontrol
      ];
    };

    services = {
      pipewire = {
        wireplumber.enable = mkDefault true;
      };
    };
  };
}

