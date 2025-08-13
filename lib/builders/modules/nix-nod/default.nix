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

    substituters = nixSubstituters.substituters ++ [
      "https://nix-on-droid.cachix.org"
    ];
    trustedPublicKeys = nixSubstituters.trusted-public-keys ++ [
      "nix-on-droid.cachix.org-1:56snoMJTXmDRC1Ei24CmKoUqvHJ9XCp+nidK7qkMQrU="
    ];
  };
}
