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

    networking = {
      # Age of Empires II: DE in-game LAN lobby hosting
      # https://support.ageofempires.com/hc/en-us/articles/360048249391
      firewall = {
        allowedTCPPorts = [
          3478
          5222
          8888
        ];
        allowedUDPPorts = [
          3478
          5222
          9999
        ];
      };
      # AoE II DE hangs creating a LAN lobby when gethostname() resolves to a
      # loopback address (https://github.com/ValveSoftware/Proton/issues/3189).
      # Drop the static 127.0.0.2 hostname entry so lookups fall through to
      # nss-myhostname, which returns the current real LAN IP dynamically.
      hosts."127.0.0.2" = mkForce [ ];
    };

    # Xbox controller
    hardware.xpadneo.enable = true;
  };
}
