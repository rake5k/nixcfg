{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.nas.samba;

  inherit (config.custom.base) hostname;
  inherit (lib) getExe mkEnableOption mkIf;

  shareBaseFolder = "/data/share";
  recycleFolder = "${shareBaseFolder}/.recycle";
  recycleFolderRetentionDays = 60;
  defaultValidUsers = [
    "christian"
    "sophie"
  ];

in

{
  options = {
    custom.roles.nas.samba = {
      enable = mkEnableOption "Samba config";
    };
  };

  config = mkIf cfg.enable {
    services.samba = {
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          workgroup = "WORKGROUP";
          "server string" = hostname;
          "netbios name" = hostname;
          security = "user";
          "hosts allow" = "172.16. 192.168.0. 10.0.10. 127.0.0.1 localhost";
          "hosts deny" = "0.0.0.0/0";
          "invalid users" = [
            "root"
            "admin"
          ];
          "guest account" = "nobody";
          "map to guest" = "bad user";

          # Enable recycle bin.
          "vfs object" = "recycle";
          "recycle:repository" = "${recycleFolder}/%S";
          "recycle:keeptree" = "yes";
          "recycle:versions" = "yes";
          "recycle:touch" = "yes";
          "recylce:exclude_dir" = "/tmp /TMP /temp /TEMP /public /cache /CACHE";
          "recycle:exclude" = "*.TMP *.tmp *.temp ~$* *.log *.bak";
        };

        homes = {
          browseable = "no";
          writable = "yes";
          "create mask" = "0600";
          "directory mask" = "0700";
          "valid users" = "%S";
        };

        photo = {
          comment = "Photo Gallery";
          path = "/data/photo";
          browsable = "yes";
          writable = "yes";
          "create mask" = "0664";
          "directory mask" = "0775";
          "valid users" = defaultValidUsers;
        };

        plex = {
          comment = "Plex Media";
          path = "/data/plex";
          browsable = "yes";
          writable = "yes";
          "create mask" = "0664";
          "directory mask" = "0775";
          "valid users" = defaultValidUsers;
          "force user" = "plex";
          "force group" = "plex";
        };

        private = {
          comment = "Private File Sharing";
          path = "${shareBaseFolder}/private";
          browsable = "yes";
          writable = "yes";
          "create mask" = "0660";
          "directory mask" = "0770";
          "valid users" = defaultValidUsers;
        };

        public = {
          comment = "Public File Sharing";
          path = "${shareBaseFolder}/public";
          browsable = "yes";
          writable = "yes";
          "guest ok" = "yes";
          "create mask" = "0666";
          "directory mask" = "0777";
        };
      };
    };

    systemd = {
      services.samba-recycle-cleanup = {
        description = "Cleanup old files from the recycle bin";
        script = ''
          #!/usr/bin/env bash
          recyclePath="${recycleFolder}"
          maxStoreDays="${toString recycleFolderRetentionDays}"

          # Delete files older than maxStoreDays
          ${getExe pkgs.findutils} "$recyclePath" -type f -mtime +$maxStoreDays -print -delete

          # Delete empty directories
          ${getExe pkgs.findutils} "$recyclePath" -mindepth 1 -type d -empty -print -delete
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };

      timers.samba-recycle-cleanup = {
        description = "Run samba-recycle-cleanup daily";
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
        wantedBy = [ "timers.target" ];
      };

      tmpfiles.rules = [
        "d ${shareBaseFolder}/private 0775 root root -"
        "d ${shareBaseFolder}/public 0777 root root -"
        "d ${recycleFolder} 0777 root root -"
      ];
    };
  };
}
