{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.gaming;

in

{
  options = {
    custom.roles.gaming = {
      enable = mkEnableOption "Gaming computer config";
    };
  };

  config = mkIf cfg.enable {
    custom.roles.backup.rsync.jobs.backup.excludes = [
      "/home/*/.steam*"
      "/home/*/.local/share/Steam"
    ];

    programs = {
      gamemode = {
        enable = true;
        settings = {
          custom = {
            start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
            end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
          };
        };
      };
      steam = {
        enable = true;
        dedicatedServer.openFirewall = true;
        remotePlay.openFirewall = true;
      };
    };

    # Xbox controller
    hardware.xpadneo.enable = true;
  };
}
