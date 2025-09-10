{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.desktop.xserver.locker;

  inherit (config.lib.custom) mkWritableConfigFile;
  inherit (lib)
    getExe
    mkEnableOption
    mkIf
    mkOption
    types
    ;

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

      lockerCmd = mkOption {
        type = types.str;
        default = "${getExe pkgs.betterlockscreen} --lock dim";
        description = "Command to activate locker";
      };

      wallpapersDir = mkOption {
        type = types.path;
        description = "Path to the wallpaper images";
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
            command = cfg.lockerCmd;
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

    xdg.configFile = mkWritableConfigFile config "caffeine/whitelist.txt" {
      text = ''
        nix
        rsync
      '';
    };

    # Update random lock image on login
    xsession.initExtra = ''
      ${getExe pkgs.betterlockscreen} --update ${cfg.wallpapersDir} --fx dim &
    '';
  };
}
