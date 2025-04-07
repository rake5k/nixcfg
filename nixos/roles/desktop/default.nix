{ config, lib, ... }:

with lib;

let

  cfg = config.custom.roles.desktop;

  inherit (config.custom.base) hostname;
  backupId = "id_ed25519_backup";

in

{
  options = {
    custom.roles.desktop = {
      enable = mkEnableOption "Desktop computer config";
    };
  };

  config = mkIf cfg.enable {
    custom = {
      base.agenix.secrets = [ backupId ];
      programs.direnv.enable = true;
      roles = {
        backup.rsync = {
          enable = true;
          jobs.backup = {
            identityFile = config.age.secrets.${backupId}.path;
            excludes = [
              "/home/*/code/*"
              "/home/*/Nextcloud/*"
            ];
            paths = [
              "/home"
            ];
            target = "backup@sv-syno-01.home.local:/volume1/NetBackup/${hostname}";
          };
        };
        printing.enable = true;
        sound.enable = true;
      };
    };

    security.pam.services.login.enableGnomeKeyring = true;

    services = {
      udisks2.enable = true;

      xserver = {
        enable = true;
        desktopManager.xterm.enable = true;
        serverFlagsSection = ''
          Option "BlankTime" "0"
          Option "StandbyTime" "0"
          Option "SuspendTime" "0"
          Option "OffTime" "0"
        '';
      };
    };
  };
}
