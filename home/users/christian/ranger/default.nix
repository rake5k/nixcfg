{ config, lib, ... }:

with lib;

let

  cfg = config.custom.users.christian.ranger;

in

{
  options = {
    custom.users.christian.ranger = {
      enable = mkEnableOption "Ranger config";
    };
  };

  config = mkIf cfg.enable {
    custom.programs.ranger.enable = true;
  };
}
