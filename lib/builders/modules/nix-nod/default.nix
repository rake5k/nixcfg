{ lib, pkgs, ... } @args:

let

  nixCommons = import ../nix-commons args;
  nixSubstituters = import ../nix-commons/substituters.nix;

in

lib.recursiveUpdate nixCommons {
  nix = {
    substituters = nixSubstituters.substituters ++ [
      "https://nix-on-droid.cachix.org"
    ];
    trustedPublicKeys = nixSubstituters.trusted-public-keys ++ [
      "nix-on-droid.cachix.org-1:56snoMJTXmDRC1Ei24CmKoUqvHJ9XCp+nidK7qkMQrU="
    ];
    nixPath = [ "nixpkgs=flake:nixpkgs" ];
  };
}
