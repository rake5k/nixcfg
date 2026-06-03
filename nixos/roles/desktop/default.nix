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
              "/home/*/Nextcloud/*.log"
              "/home/*/.mozilla/firefox/*/Crash Reports/"
              "/home/*/.mozilla/firefox/*/lock"
              "/home/*/.mozilla/firefox/*/storage/default"
              "/home/*/.mozilla/firefox/*/storage/temporary"
              "/home/*/bluecare/*"
              "/home/*/code/*"
              "/home/*/Nextcloud/*"
            ];
            paths = [
              "/home"
            ];
            target = "backup@sv-syno-01.lan.harke.ch:/volume1/NetBackup/${hostname}";
          };
        };
        printing.enable = true;
        sound.enable = true;
      };
    };

    security.pam.services = {
      # Enable pam service to enable session unlocking by i3lock-based lockers:
      # https://github.com/NixOS/nixpkgs/issues/401891#issuecomment-2831813778
      i3lock = { };
      login.enableGnomeKeyring = true;
      swaylock = { };
    };

    # Use the standard openssh agent for SSH instead of gcr-ssh-agent. The
    # gcr-4 agent (shipped with gnome-keyring on 26.05) auto-loads passphrase
    # protected keys via ssh-add at login, but its prompter does not display
    # under the niri/Wayland session, so signing hangs and every ssh
    # connection blocks. gnome-keyring still handles passwords/secrets.
    programs.ssh.startAgent = true;

    services = {
      udisks2.enable = true;

      gnome.gcr-ssh-agent.enable = false;

      displayManager.sessionPackages = [ pkgs.niri ];
      xserver = {
        enable = true;
        desktopManager.cinnamon.enable = true;
        displayManager.lightdm = {
          background = pkgs.nixos-artwork.wallpapers.binary-blue.gnomeFilePath;
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
