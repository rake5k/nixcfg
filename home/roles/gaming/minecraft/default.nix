{
  lib,
  config,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.gaming.minecraft;

in

{
  options = {
    custom.roles.gaming.minecraft = {
      enable = lib.mkEnableOption "Minecraft";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      prismlauncher
      jre8
    ];
  };
}
