{
  description = "sway-gnome modules";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:coreyoconnor/nixpkgs/main";
    swayfx = {
      url = "github:WillPower3309/swayfx/master";
    };
  };

  outputs = {
    self,
    flake-utils,
    nixpkgs,
    swayfx,
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
          --exclude ./dev \
          --exclude ./.git \
          "$@"
      '';
    });
}
