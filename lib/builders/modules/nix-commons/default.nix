{
  lib,
  inputs,
  pkgs,
  ...
}:

let

  nixSubstituters = import ../nix-commons/substituters.nix;

  inherit (pkgs.stdenv) isDarwin;

in

{
  nix = {
    package = pkgs.nix;
    registry = {
      nixpkgs.flake = inputs.nixpkgs;
      nix-config.flake = inputs.self;
    };
    settings = {
      auto-optimise-store = lib.mkDefault (!isDarwin);
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      log-lines = 30;
    } // nixSubstituters;
  };
}
