{
  description = "sway-gnome modules";

  outputs = _: {
    nixosModules = {
      default = import ./default.nix;
    };
  };
}
