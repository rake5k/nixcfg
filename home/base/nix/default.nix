{ pkgs, ... }:

{
  home.packages = [
    pkgs.nix-output-monitor
  ];

  nixpkgs.config = import ./nixpkgs-config.nix;
  xdg.configFile."nixpkgs/config.nix".source = ./nixpkgs-config.nix;

  # Command-not-found replacement
  programs.nix-index.enable = true;
}
