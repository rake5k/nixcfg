{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.graphics;

in

{
  options = {
    custom.roles.graphics = {
      enable = mkEnableOption "Graphics";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ gimp ] ++ optionals pkgs.stdenv.isLinux [ sxiv ];
  };
}
