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
      "/home/*/.local/share/lutris/runners/"
      "/home/*/.local/share/lutris/runtime/"
      "/home/*/.local/share/umu/"
      "/home/*/.steam*"
      "/home/*/.local/share/Steam"
      "/home/*/Games"
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
        # 32-bit freetype/fontconfig: wine GUIs (installers, msiexec) hang
        # without them when run via steam-run outside the Steam runtime.
        package = pkgs.steam.override {
          extraLibraries = p: [
            p.freetype
            p.fontconfig
          ];
        };
      };
    };

    # Xbox controller
    hardware.xpadneo.enable = true;
  };
}
