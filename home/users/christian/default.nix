{ config, lib, ... }:

with lib;

let

  cfg = config.custom.users.christian;

in

{
  options = {
    custom.users.christian = {
      enable = mkEnableOption "User config";
    };
  };

  config = mkIf cfg.enable {
    home.username = "christian";

    custom = {
      roles.homeage.enable = true;
      users.christian = {
        bin.enable = true;
        fonts.enable = true;
        git.enable = true;
        hardware = {
          kmonad.enable = true;
          xbindkeys.enable = true;
        };
        office.cli.enable = config.custom.roles.office.cli.enable;
        ranger.enable = true;
        shell.enable = true;
        steam.enable = config.custom.roles.gaming.enable;
        vim.enable = true;
      };
    };
  };
}
