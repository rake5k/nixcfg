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

      # Workaround for GDM 50 greeter failing to find gnome-session.
      # See: https://github.com/NixOS/nixpkgs/issues/523332
      # Drop once https://github.com/NixOS/nixpkgs/pull/523948 lands in nixos-26.05.
      gdm-launch-environment.rules.session.env-greeter = {
        control = "required";
        modulePath = "${config.security.pam.package}/lib/security/pam_env.so";
        order = config.security.pam.services.gdm-launch-environment.rules.session.env.order + 50;
        settings.conffile = pkgs.writeText "gdm-launch-environment-env-conf" ''
          PATH                    DEFAULT="''${PATH}:${pkgs.gnome-session}/bin"
          XDG_DATA_DIRS           DEFAULT="''${XDG_DATA_DIRS}:${config.services.displayManager.generic.environment.XDG_DATA_DIRS}"
          GDM_X_SERVER_EXTRA_ARGS DEFAULT="${config.services.displayManager.generic.environment.GDM_X_SERVER_EXTRA_ARGS}"
        '';
        settings.readenv = 0;
      };
    };

    services = {
      udisks2.enable = true;

      displayManager = {

        gdm.enable = true;

        sessionPackages = [ pkgs.niri ];
      };
      xserver = {
        enable = true;
        desktopManager.cinnamon.enable = true;
        # GDM 50's wayland greeter leaks `XDG_SESSION_TYPE=wayland` into X11 sessions;
        # cinnamon/muffin then try to start as a wayland compositor and fail with EBUSY
        # in logind's TakeControl. Force the correct value before the session execs.
        displayManager.setupCommands = ''
          export XDG_SESSION_TYPE=x11
        '';
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
