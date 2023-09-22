{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.desktop;

in

{
  options = {
    custom.roles.desktop = {
      enable = mkEnableOption "Desktop computer config";
    };
  };

  config = mkIf cfg.enable {
    custom = {
      programs.direnv.enable = true;
      roles = {
        printing.enable = true;
        sound.enable = true;
      };
    };

    services = {
      xserver = {
        enable = true;
        desktopManager.xterm.enable = true;
        serverFlagsSection = ''
          Option "BlankTime" "0"
          Option "StandbyTime" "0"
          Option "SuspendTime" "0"
          Option "OffTime" "0"
        '';
      };
    };
  };
}
