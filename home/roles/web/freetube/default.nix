{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.web.freetube;

in

{
  options = {
    custom.roles.web.freetube = {
      enable = mkEnableOption "FreeTube";
    };
  };

  config = mkIf cfg.enable {
    custom = {
      programs.syncthing.enable = true;
    };

    home.packages = with pkgs; [ freetube ];
  };
}
