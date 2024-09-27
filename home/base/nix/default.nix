{ pkgs, ... }:

{
  home.packages = [
    pkgs.nix-output-monitor
  ];

  # Command-not-found replacement
  programs.nix-index.enable = true;
}
