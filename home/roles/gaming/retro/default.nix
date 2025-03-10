{ lib, config, ... }:

let

  cfg = config.custom.roles.gaming.retro;

  inherit (lib) mkEnableOption mkIf;

in

{
  options = {
    custom.roles.gaming.retro = {
      enable = mkEnableOption "Retro gaming";
    };
  };

  config = mkIf cfg.enable {
    custom.roles.syncthing.enable = true;
  };
}
