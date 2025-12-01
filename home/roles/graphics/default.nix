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
    custom.roles.fonts.enable = true;

    home.packages =
      with pkgs;
      optionals pkgs.stdenv.isLinux [
        gimp
        sxiv
      ];
  };
}
