{ config, lib, pkgs, ... }:

with lib;

let

  desktopCfg = config.custom.roles.desktop;
  cfg = desktopCfg.passwordManager;

in

{
  options = {
    custom.roles.desktop.passwordManager = {
      enable = mkEnableOption "Password manager";

      package = mkOption {
        type = types.package;
        default = pkgs._1password;
        description = "Password manager package";
      };

      spawnCmd = mkOption {
        type = types.str;
        default = "1password";
        description = "Command to spawn the password manager";
      };
    };
  };

  config = mkIf cfg.enable
    {
      home.packages = [ cfg.package ];
    };
}
