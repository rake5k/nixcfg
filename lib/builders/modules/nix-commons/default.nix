{
  lib,
  inputs,
  pkgs,
  ...
}:

let

  nixSubstituters = import ./substituters.nix;

  inherit (lib) mkDefault;
  inherit (pkgs.stdenv) isDarwin;

in

{
  nix = {
    package = mkDefault pkgs.nix;
    registry = {
      nixpkgs.flake = inputs.nixpkgs;
      nix-config.flake = inputs.self;
    };
    settings = {
      auto-optimise-store = mkDefault (!isDarwin);
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      log-lines = 30;
    }
    // nixSubstituters;
  };
}
