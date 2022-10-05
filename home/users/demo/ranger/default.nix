{ config, lib, ... }:

with lib;

let

  cfg = config.custom.users.demo.ranger;

in

{
  options = {
    custom.users.demo.ranger = {
      enable = mkEnableOption "Ranger config";
    };
  };

  config = mkIf cfg.enable {
    custom.programs.ranger.enable = true;
  };
}
