{ pkgs, config, lib, inputs, ... }:

{
  nix = {
    nixPath = [ "nixpkgs=flake:nixpkgs" ];
    registry = {
      nixpkgs.flake = inputs.nixpkgs;
      nix-config.flake = inputs.self;
    };
    settings = {
      allowed-users = builtins.attrNames config.users.users;
      experimental-features = [ "nix-command" "flakes" ];
      log-lines = 30;
      substituters = [
        "https://christianharke.cachix.org/"
        "https://nix-community.cachix.org"
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [
        "christianharke.cachix.org-1:TzmbiNLRcH8G0932XRlQzh8GPvuV9pJcHLqLnzznLKU="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
    };
  };

  system.activationScripts.diff = {
    supportsDryActivation = true;
    text = ''
      if [[ -e /run/current-system ]]; then
         ${lib.getExe pkgs.nix} store diff-closures /run/current-system "$systemConfig"
      fi
    '';
  };
}
