{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.users.christian.git;

in

{
  options = {
    custom.users.christian.git = {
      enable = mkEnableOption "Git";
    };
  };

  config = mkIf cfg.enable {
    custom.programs.lazygit.enable = true;

    home.packages = with pkgs; [
      git-crypt
    ];

    programs.git = {
      enable = true;
      userName = "Christian Harke";
      signing.key = "630966F4";

      aliases = import ./aliases.nix;
      delta.enable = true;
      ignores = import ./ignores.nix;
      lfs.enable = true;
      extraConfig = {
        rerere.enabled = true;
      };
    };
  };
}
