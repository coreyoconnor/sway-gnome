{
  description = "sway-gnome modules";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:coreyoconnor/nixpkgs/main";
  };

  outputs = {
    self,
    flake-utils,
    nixpkgs,
  }:
    {
      nixosModules = {
        default = import ./default.nix;
      };
    }
    // flake-utils.lib.eachDefaultSystem (system: {
      formatter = nixpkgs.legacyPackages.${system}.writeScriptBin "alejandra" ''
        exec ${nixpkgs.legacyPackages.${system}.alejandra}/bin/alejandra \
          --exclude ./dev-dependencies \
          --exclude ./.git \
          "$@"
      '';
    });
}
