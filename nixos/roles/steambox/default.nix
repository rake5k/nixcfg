{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.steambox;
  steam_autostart = pkgs.makeAutostartItem {
    name = "steam";
    package = pkgs.steam;
  };

in

{
  options = {
    custom.roles.steambox = {
      enable = mkEnableOption "Steam box config";
    };
  };

  config = mkIf cfg.enable {
    custom = {
      base.users = [ "gamer" ];
      roles = {
        gaming.enable = true;
        sound.enable = true;
      };
    };

    environment.systemPackages = with pkgs; [
      # Steam
      steam_autostart
      steam-run

      # Other launchers
      heroic
      lutris

      # Games
      pinball
      space-cadet-pinball
      superTux
      superTuxKart

      # Geforce NOW
      chromium
      firefox
    ];

    # Enable the KDE Desktop Environment.
    services = {
      displayManager = {
        sddm.enable = true;
        autoLogin = {
          enable = true;
          user = "gamer";
        };
      };
      xserver = {
        enable = true;
        desktopManager.plasma5.enable = true;
      };
    };
  };
}
