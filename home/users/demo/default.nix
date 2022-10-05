{ config, lib, ... }:

with lib;

let

  cfg = config.custom.users.demo;

in

{
  options = {
    custom.users.demo = {
      enable = mkEnableOption "User config";
    };
  };

  config = mkIf cfg.enable {
    home.username = "demo";

    custom = {
      users.demo = {
        ranger.enable = true;
      };
    };
  };
}
