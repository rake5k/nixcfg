{ lib, pkgs, ... } @args:

let

  nixCommons = import ../nix-commons args;
  nixSubstituters = import ../nix-commons/substituters.nix;

in

lib.recursiveUpdate nixCommons {
  nix = {
    inherit (nixSubstituters) substituters;
    trustedPublicKeys = nixSubstituters.trusted-public-keys;
    nixPath = [ "nixpkgs=flake:nixpkgs" ];
  };
}
