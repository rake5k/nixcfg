{
  pkgs,
  lib,
  config,
  ...
}:

let

  cfg = config.custom.roles.backup.rsync;

  inherit (lib)
    getExe
    mapAttrs'
    mkEnableOption
    mkIf
    mkOption
    nameValuePair
    types
    ;
  inherit (lib.strings) concatStringsSep optionalString;

  job = types.submodule {
    options = {
      identityFile = mkOption {
        type = types.str;
        description = "Identity file to use";
        example = "/root/.ssh/id_example";
      };

      excludes = mkOption {
        type = with types; listOf str;
        description = "Directories and files to be excluded";
        default = [
          "/dev/*"
          "/home/*/.thumbnails/*"
          "/home/*/.cache/mozilla/*"
          "/home/*/.cache/chromium/*"
          "/home/*/.local/share/Trash/*"
          "/media/*"
          "/mnt/*"
          "/nix/store/*"
          "/lost+found/"
          "/persist/var/cache/*"
          "/persist/var/lib/containers/storage/overlay*"
          "/persist/var/lib/samba/private/msg.sock/*"
          "/proc/*"
          "/run/*"
          "/sys/*"
          "/tmp/*"
          "/var/cache/*"
          "/var/lib/containers/storage/overlay*"
          "/var/lib/samba/private/msg.sock/*"
          "/var/log/*"
          "/var/tmp/*"
        ];
      };

      paths = mkOption {
        type = with types; listOf str;
        description = "Directories and files to be backed up";
      };

      target = mkOption {
        type = types.str;
        description = "Target directory to back up to";
        example = "remoteuser@remotehost:/location/of/backup";
      };
    };
  };

  mkEachService =
    let
      mkIdentity =
        identityFile:
        optionalString (identityFile != null) "--rsh='${getExe pkgs.openssh} -i ${identityFile}'";
      mkExcludes = excludes: concatStringsSep " " (map (exclude: "--exclude '${exclude}'") excludes);
      mkIncludes = concatStringsSep " ";
      mkCmd = concatStringsSep " ";
    in
    mapAttrs' (
      name: value:
      nameValuePair "rsync-${name}" {
        description = "Back up files using rsync";
        serviceConfig.Type = "oneshot";
        path = [ pkgs.rsync ];
        script = mkCmd [
          (getExe pkgs.rsync)
          "--archive --acls --xattrs --relative --hard-links --compress --delete-after --verbose"
          "--rsync-path='rsync --fake-super'"
          (mkIdentity value.identityFile)
          (mkExcludes value.excludes)
          (mkIncludes value.paths)
          value.target
        ];
        startAt = "00:00";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
      }
    );

  mkEachTimer = mapAttrs' (
    name: _value:
    nameValuePair "rsync-${name}" {
      timerConfig = {
        RandomizedDelaySec = 600;
        Persistent = true;
      };
    }
  );

in

{
  options = {
    custom.roles.backup.rsync = {
      enable = mkEnableOption "Rsync backup";

      jobs = mkOption {
        description = "Set of rsync backup jobs";
        default = { };
        type = types.attrsOf job;
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.rsync ];

    systemd = {
      services = mkEachService cfg.jobs;
      timers = mkEachTimer cfg.jobs;
    };
  };
}
