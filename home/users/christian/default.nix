{ config, lib, ... }:

with lib;

let

  username = "christian";
  cfg = config.custom.users."${username}";

in

{
  options = {
    custom.users."${username}" = {
      enable = mkEnableOption "User config";
    };
  };

  config = mkIf cfg.enable {
    home.username = mkDefault username;

    custom = {
      roles.homeage.enable = true;

      users."${username}" = {
        fonts.enable = !config.custom.roles.mobile.enable;
        git.enable = true;
        gpg.enable = true;
        mobile.enable = config.custom.roles.mobile.enable;
        office.cli.enable = config.custom.roles.office.cli.enable;
        shell.enable = true;
        ssh.enable = true;
        vim.enable = true;
      };
    };
  };
}
