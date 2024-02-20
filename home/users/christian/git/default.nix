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

      aliases = import ./aliases.nix;
      delta.enable = true;
      ignores = import ./ignores.nix;
      lfs.enable = true;
      extraConfig = {
        # sign by ssh
        gpg.format = "ssh";
        user.signingkey = "/PATH/TO/.SSH/KEY.PUB";
        commit.gpgSign = true;
        tag.gpgSign = true;

        rerere.enabled = true;
      };
    };
  };
}
