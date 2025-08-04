{
  lib,
  inputs,
  pkgs,
  ...
}:

let

  nixSubstituters = import ../nix-commons/substituters.nix;

  inherit (lib) mkDefault;

in

{
  nix = {
    package = mkDefault pkgs.nix;
    nixPath = [ "nixpkgs=flake:nixpkgs" ];
    registry = {
      nixpkgs.flake = inputs.nixpkgs;
      nix-config.flake = inputs.self;
    };

    inherit (nixSubstituters) substituters;
    trustedPublicKeys = nixSubstituters.trusted-public-keys;
  };
}
