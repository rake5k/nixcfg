{ lib, inputs, pkgs, ... } @args:

let

  nixCommons = import ../nix-commons args;

in

{
  nix = {
    inherit (nixCommons.nix) package registry;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };
}
