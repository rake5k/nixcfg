{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.office;

in

{
  options = {
    custom.roles.office = {
      enable = mkEnableOption "Office";
    };
  };

  config = mkIf cfg.enable {
    custom.roles.fonts.enable = true;

    home.packages =
      with pkgs;
      [ reveal-md ]
      ++ optionals pkgs.stdenv.isLinux [
        libreoffice
        openjdk
      ];
  };
}
