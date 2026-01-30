{
  description = "sway-gnome modules";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    swayfx = {
      url = "github:WillPower3309/swayfx/master";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
      };
    };
    waybar = {
      url = "github:Alexays/Waybar/master";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
      };
    };
  };

  outputs = {
    self,
    flake-utils,
    nixpkgs,
    nixpkgs-unstable,
    swayfx,
    waybar,
  }:
    {
      nixosModules = {
        default = import ./module.nix { inherit swayfx waybar; };
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
