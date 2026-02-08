{ pkgs, ... }:

{
  home.packages = [ pkgs.nix-output-monitor ];

  # Command-not-found replacement
  programs.nix-index.enable = true;

  services.home-manager.autoExpire = {
    enable = true;
    frequency = "weekly";
    timestamp = "-30 days";
  };
}
