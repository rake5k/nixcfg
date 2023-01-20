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
        f:/mnt/home/photo
        h:/mnt/home/home
        m:/mnt/home/music
        p:/mnt/home/public
        s:/mnt/home/home/Scan
        v:/mnt/home/video
      '';
    };
  };
}
