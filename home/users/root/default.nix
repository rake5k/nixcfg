{ config, lib, ... }:

let

  username = "root";
  cfg = config.custom.users."${username}";

  inherit (lib) mkDefault mkEnableOption mkIf;

in

{
  options = {
    custom.users."${username}" = {
      enable = mkEnableOption "User config";
    };
  };

  config = mkIf cfg.enable {
    home = {
      username = mkDefault username;
    };

    custom = {
      users."${username}" = {
        ssh.enable = true;
      };
    };
  };
}
