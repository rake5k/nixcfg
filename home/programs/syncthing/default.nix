{ lib, config, ... }:

let

  cfg = config.custom.programs.syncthing;

in

{
  options = {
    custom.programs.syncthing = {
      enable = lib.mkEnableOption "Syncthing";
    };
  };

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;
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
