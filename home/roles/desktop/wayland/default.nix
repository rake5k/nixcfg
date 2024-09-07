{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.desktop.wayland;

in

{
  options = {
    custom.roles.desktop.wayland = {
      enable = mkEnableOption "Wayland config";
    };
  };

  config = mkIf cfg.enable {
    custom.roles.desktop.wayland.river.enable = true;

    home.packages = with pkgs; [
      wl-clipboard
    ];

    xsession.enable = true;
  };
}
