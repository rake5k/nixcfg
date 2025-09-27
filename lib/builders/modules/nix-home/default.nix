{
  lib,
  inputs,
  pkgs,
  ...
}:

let

  nixCommons = import ../nix-commons { inherit lib inputs pkgs; };
  nixSubstituters = import ../nix-commons/substituters.nix;

in

{
  nix = {
    inherit (nixCommons.nix) package registry;

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    }
    // nixSubstituters;
  };
}
