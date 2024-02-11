{ config, lib, pkgs, ... }:

with lib;

let

  desktopCfg = config.custom.roles.desktop;
  cfg = desktopCfg.locker;

in

{
  options = {
    custom.roles.desktop.locker = {
      package = mkOption {
        type = types.package;
        default = pkgs.betterlockscreen;
        description = "Locker package to use";
      };

      lockCmd = mkOption {
        type = types.str;
        default = "${lib.getExe pkgs.betterlockscreen} --lock dim";
        description = "Command to activate locker";
      };
    };
  };

  config = mkIf desktopCfg.enable {
    home.packages = [
      cfg.package
    ] ++ (with pkgs; [
      playerctl
    ]);

    services.xidlehook = {
      enable = true;
      detect-sleep = true;
      not-when-audio = true;
      not-when-fullscreen = true;
      timers = [
        {
          delay = 600;
          command = cfg.lockCmd;
        }
        {
          delay = 300;
          command = ''
            systemctl suspend
          '';
        }
      ];
    };

    # Update random lock image on login
    xsession.initExtra = ''
      ${lib.getExe pkgs.betterlockscreen} --update ${desktopCfg.wallpapersDir} --fx dim &
    '';
  };
}
