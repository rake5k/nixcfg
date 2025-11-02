{
  config,
  lib,
  pkgs,
  ...
}:

let

  inherit (lib) mkEnableOption mkIf;

  cfg = config.custom.roles.gaming;

in

{
  options = {
    custom.roles.gaming = {
      enable = mkEnableOption "Gaming";
    };
  };

  config = mkIf cfg.enable {
    custom.roles.gaming = {
      comms.enable = true;
      mangohud.enable = true;
      streaming.enable = true;
    };

    home.packages = with pkgs; [
      # Game libs
      heroic
      unstable.lutris
      steam

      # Runtimes
      wineWowPackages.stable

      # Tinkering
      unstable.winetricks
      unstable.protontricks
    ];
  };
}
