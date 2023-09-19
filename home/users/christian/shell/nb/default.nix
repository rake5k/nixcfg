{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.users.christian.shell.nb;

in

{
  options = {
    custom.users.christian.shell.nb = {
      enable = mkEnableOption "nb";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      nb

      # Optional dependencies:
      bat
      nmap
      pandoc
      ripgrep
      tig
      w3m
    ];
  };
}
