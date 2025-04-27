{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.web.freetube;

  inherit (lib) mkEnableOption mkIf;

in

{
  options = {
    custom.roles.web.freetube = {
      enable = mkEnableOption "FreeTube";
    };
  };

  config = mkIf cfg.enable {
    custom.roles.syncthing.enable = true;

    home.packages = with pkgs.unstable; [ freetube ];
  };
}
