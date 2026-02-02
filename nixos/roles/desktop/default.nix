{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.desktop;

  inherit (lib) mkEnableOption mkIf;

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
              "/home/*/.mozilla/firefox/*/storage/default"
              "/home/*/.mozilla/firefox/*/storage/temporary"
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

    security.pam.services = {
      # Enable pam service to enable session unlocking by i3lock-based lockers:
      # https://github.com/NixOS/nixpkgs/issues/401891#issuecomment-2831813778
      i3lock.enable = true;
      login.enableGnomeKeyring = true;
    };

    services = {
      udisks2.enable = true;

      xserver = {
        enable = true;
        desktopManager.cinnamon.enable = true;
        displayManager.lightdm = {
          greeter.package = pkgs.unstable.lightdm-slick-greeter.xgreeters;
          greeters.slick.enable = true;
        };
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
