{ lib, config, ... }:

let

  cfg = config.custom.roles.syncthing;

in

{
  options = {
    custom.roles.syncthing = {
      enable = lib.mkEnableOption "Syncthing";
    };
  };

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;

      settings = {
        devices = {
          hyperion = {
            addresses = [ "tcp://hyperion.home.local:22000" ];
            id = "HBOUOH2-BYJTO4T-BYBYO3W-KLSUIBY-RLOEC57-X7YIZGH-PKHEUFT-PJXMYAK";
          };
        };

        options = {
          globalAnnounceEnabled = false;
          relaysEnabled = false;
          urAccepted = -1;
        };
      };

      tray = {
        enable = true;
        command = "syncthingtray --wait";
      };
    };

    # Syncthingtray service requires tray.target
    systemd.user.targets.tray = {
      Unit = {
        Description = "Home Manager System Tray";
        Requires = [ "graphical-session-pre.target" ];
      };
    };
  };
}
