{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.gaming.mangohud;

in

{
  options = {
    custom.roles.gaming.mangohud = {
      enable = mkEnableOption "MangoHud";
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [ mangohud ];
    };

    xdg.configFile.MangoHud = {
      recursive = true;
      source = ./configs;
    };
  };
}
