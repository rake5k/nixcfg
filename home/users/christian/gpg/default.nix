{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.users.christian.gpg;

in

{
  options = {
    custom.users.christian.gpg = {
      enable = mkEnableOption "GnuPG";
    };
  };

  config = mkIf cfg.enable {

    home.file.".gnupg/gpg-agent.conf" = {
      text = ''
        pinentry-program ${getExe pkgs.pinentry-gnome3}
      '';
    };

    programs.gpg.enable = true;
  };
}
