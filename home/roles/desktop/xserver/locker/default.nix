{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.desktop.xserver.locker;

in

{
  options = {
    custom.roles.desktop.xserver.locker = {
      enable = mkEnableOption "Xorg screen locker";

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

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ] ++ (with pkgs; [ playerctl ]);

    services = {
      caffeine.enable = true;
      xidlehook = {
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
    };

    xdg.configFile."caffeine/whitelist.txt".text = ''
      nix
      rsync
    '';

    # Update random lock image on login
    xsession.initExtra = ''
      ${lib.getExe pkgs.betterlockscreen} --update ${inputs.wallpapers} --fx dim &
    '';
  };
}
