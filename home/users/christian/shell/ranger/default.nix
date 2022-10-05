{ config, lib, ... }:

with lib;

let

  cfg = config.custom.users.christian.shell.ranger;

in

{
  options = {
    custom.users.christian.shell.ranger = {
      enable = mkEnableOption "Ranger file manager";
    };
  };

  config = mkIf cfg.enable {
    custom.programs.ranger = {
      enable = true;
      bookmarks = ''
        # Common
        d:${config.home.homeDirectory}/Downloads
        h:/mnt/home/home
      '';
    };
  };
}
