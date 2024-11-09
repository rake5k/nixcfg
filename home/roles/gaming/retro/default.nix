{ lib, config, ... }:

let

  cfg = config.custom.roles.gaming.retro;

in

{
  options = {
    custom.roles.gaming.retro = {
      enable = lib.mkEnableOption "Retro gaming";
    };
  };

  config = lib.mkIf cfg.enable { custom.programs.syncthing.enable = true; };
}
