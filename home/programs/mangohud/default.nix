{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.programs.mangohud;

in

{
  options = {
    custom.programs.mangohud = {
      enable = mkEnableOption "MangoHud";
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        mangohud
      ];
    };

    xdg.configFile.MangoHud = {
      recursive = true;
      source = ./configs;
    };
  };
}
