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
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    nameValuePair
    types
    ;
  inherit (lib.strings) concatStringsSep optionalString;

  defaultExcludes = [
    "/dev/*"
    "/home/*/.thumbnails/*"
    "/home/*/.cache/*"
    "/home/*/.local/share/Trash/*"
    "/media/*"
    "/mnt/*"
    "/nix/store/*"
    "/lost+found/"
    "/persist/var/cache/*"
    "/persist/var/lib/containers/storage/overlay*"
    "/persist/var/lib/samba/*"
    "/proc/*"
    "/run/*"
    "/sys/*"
    "/tmp/*"
    "/var/cache/*"
    "/var/lib/containers/storage/overlay*"
    "/var/lib/samba/*"
    "/var/log/*"
    "/var/tmp/*"
  ];

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
        default = defaultExcludes;
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

  mkIdentity =
    identityFile:
    optionalString (
      identityFile != null
    ) "--rsh='${getExe pkgs.openssh} -i ${identityFile} -o StrictHostKeyChecking=no'";
  mkExcludes =
    excludes:
    concatStringsSep " " (map (exclude: "--exclude '${exclude}'") (defaultExcludes ++ excludes));
  mkIncludes = concatStringsSep " ";
  mkCmd = concatStringsSep " ";
  rsyncCmd = mkCmd [
    (getExe pkgs.rsync)
    "--rsync-path='rsync --fake-super'"
    "--archive --acls --xattrs --relative --hard-links --compress --verbose"
  ];

  mkEachRestoreScript = mapAttrsToList (
    name: value:
    with pkgs;
    writeShellApplication (
      let
        restoreCmd = mkCmd [
          "sudo"
          rsyncCmd
          (mkIdentity value.identityFile)
          "\"${value.target}/.$1\""
          "/"
        ];
      in
      {
        name = "rsync-${name}-restore";
        runtimeInputs = [ rsync ];
        text = ''
          if [ $# -ne 1 ]; then
            echo "Usage: $0 <restore-path>"
            exit 1
          fi

          if [[ "$1" != /* ]]; then
            echo "The restore path must start with '/'"
            exit 1
          fi

          ${restoreCmd}
        '';
      }
    )
  );

  mkEachService = mapAttrs' (
    name: value:
    nameValuePair "rsync-${name}" {
      description = "Back up files using rsync";
      serviceConfig.Type = "oneshot";
      path = [ pkgs.rsync ];
      script = mkCmd [
        rsyncCmd
        "--delete-after --delete-excluded"
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
    environment.systemPackages = [
      pkgs.rsync
    ] ++ mkEachRestoreScript cfg.jobs;

    systemd = {
      services = mkEachService cfg.jobs;
      timers = mkEachTimer cfg.jobs;
    };
  };
}
