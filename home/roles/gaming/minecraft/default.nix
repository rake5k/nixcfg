{
  lib,
  config,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.gaming.minecraft;

  prismlauncher = config.lib.nixGL.wrap pkgs.prismlauncher;

in

{
  options = {
    custom.roles.gaming.minecraft = {
      enable = lib.mkEnableOption "Minecraft";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      prismlauncher
      pkgs.jre8
    ];
  };
}
