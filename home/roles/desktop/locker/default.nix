{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.desktop.locker;

in

{
  options = {
    custom.roles.desktop.locker = {
      package = mkOption {
        type = types.package;
        default = pkgs.custom.i3lock-pixeled;
        description = "Locker package to use";
      };

      lockCmd = mkOption {
        type = types.str;
        default = "${pkgs.custom.i3lock-pixeled}/bin/i3lock-pixeled";
        description = "Command to activate locker";
      };
    };
  };
}
