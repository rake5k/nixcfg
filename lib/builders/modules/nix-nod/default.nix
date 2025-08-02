{ lib, ... }@args:

let

  nixCommons = import ../nix-commons args;
  nixSubstituters = import ../nix-commons/substituters.nix;

in

lib.recursiveUpdate nixCommons {
  nix = {
    nixPath = [ "nixpkgs=flake:nixpkgs" ];
    settings = {
      auto-optimise-store = false;
    };
  }
  // nixSubstituters;
}
