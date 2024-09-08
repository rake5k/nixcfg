{ lib, inputs, pkgs, ... }:

let

  nixCommons = import ../nix-commons { inherit lib inputs pkgs; };

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
