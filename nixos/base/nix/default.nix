{ pkgs, inputs, ... }:

{
  nix = {
    gc = {
      automatic = true;
      dates = "04:00";
      options = "--delete-older-than 7d";
    };
    nixPath = [ "nixpkgs=flake:nixpkgs" ];
    optimise.automatic = true;
    registry = {
      nixpkgs.flake = inputs.nixpkgs;
      nix-config.flake = inputs.self;
    };
    settings = {
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

  nixpkgs.config.allowUnfree = true;
}
