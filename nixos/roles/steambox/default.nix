{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.steambox;

  inherit (lib) mkEnableOption mkIf;

  inherit (config.custom.base) hostname;
  backupId = "id_ed25519_backup";

  steam_autostart = pkgs.makeAutostartItem {
    name = "steam";
    package = pkgs.steam;
  };

  username = "gamer";

in

{
  options = {
    custom.roles.steambox = {
      enable = mkEnableOption "Steam box config";
    };
  };

  config = mkIf cfg.enable {
    custom = {
      base.agenix.secrets = [ backupId ];
      base.users = [ "gamer" ];
      roles = {
        gaming.enable = true;
        sound.enable = true;
        backup.rsync = {
          enable = true;
          jobs.backup = {
            identityFile = config.age.secrets.${backupId}.path;
            paths = [
              "/home"
            ];
            target = "backup@sv-syno-01.home.local:/volume1/NetBackup/${hostname}";
          };
        };
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
      desktopManager.plasma6.enable = true;
      displayManager = {
        sddm.enable = true;
        autoLogin.user = "gamer";
      };
      xserver.enable = true;
    };

    users.users."${username}" = {
      name = username;
      isNormalUser = true;
      password = "";
    };
  };
}
