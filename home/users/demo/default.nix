{ config, lib, ... }:

with lib;

let

  username = "demo";
  cfg = config.custom.users."${username}";

in

{
  options = {
    custom.users."${username}" = {
      enable = mkEnableOption "User config";
    };
  };

  config = mkIf cfg.enable {
    home = {
      inherit username;
      homeDirectory = "/home/${username}";
    };

    custom.roles = {
      desktop.enable = true;
      dev.enable = true;
      gaming.enable = true;
      graphics.enable = true;
      homeage.enable = true;
      multimedia.enable = true;
      office.enable = true;
      ops.enable = true;
      web.enable = true;
    };
  };
}
