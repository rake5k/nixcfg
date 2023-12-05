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

    # Update random lock image on login
    xsession.initExtra = ''
      ${lib.getExe pkgs.betterlockscreen} --update ${desktopCfg.wallpapersDir} --fx dim &
    '';
  };
}
