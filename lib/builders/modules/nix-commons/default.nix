{ lib, inputs, pkgs, ... }:

{
  nix = {
    package = pkgs.nix;
    registry = {
      nixpkgs.flake = inputs.nixpkgs;
      nix-config.flake = inputs.self;
    };
  };
}
