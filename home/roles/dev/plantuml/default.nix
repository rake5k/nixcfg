{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.dev.plantuml;

in

{
  options = {
    custom.roles.dev.plantuml = {
      enable = mkEnableOption "Plant UML";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      plantuml
      graphviz
    ];
  };
}
