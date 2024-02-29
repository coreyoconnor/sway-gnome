{
  description = "sway-gnome modules";

  outputs = _: {
    nixosModules = {
      retronix = import ./default.nix;
    };
  };
}
