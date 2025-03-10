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
        options = {
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
