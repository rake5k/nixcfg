{ config, lib, pkgs, ... }:

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
    custom.roles = {
      gaming.enable = true;
      sound.enable = true;
    };

    environment.systemPackages = with pkgs; [
      steam_autostart
      steam-run
    ];

    # Enable the KDE Desktop Environment.
    services.xserver = {
      enable = true;
      desktopManager.plasma5.enable = true;
      displayManager = {
        sddm.enable = true;
        autoLogin = {
          enable = true;
          user = "gamer";
        };
      };
    };

    users = {
      users = {
        gamer = {
          password = "";
          isNormalUser = true;
        };
      };
    };

    #systemd.extraConfig = "DefaultLimitNOFILE=1048576";
    #boot.kernelPackages = pkgs.linuxPackages_latest;
  };
}
