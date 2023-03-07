{ config, pkgs, ... }:

{
  nix = {
    settings = {
      auto-optimise-store = true;
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
  nixpkgs.config = import ./nixpkgs-config.nix;
  xdg.configFile."nixpkgs/config.nix".source = ./nixpkgs-config.nix;

  # Command-not-found hook
  programs.command-not-found = {
    enable = true;
    dbPath = config.lib.custom.programsdb;
  };
}
