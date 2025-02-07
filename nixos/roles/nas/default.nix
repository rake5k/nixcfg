{ config, lib, ... }:

let

  cfg = config.custom.roles.nas;

  inherit (config.custom.base) hostname;
  inherit (lib) mkEnableOption mkIf;

in

{
  options = {
    custom.roles.nas = {
      enable = mkEnableOption "NAS config";
    };
  };

  config = mkIf cfg.enable {
    custom = {
      base.system = {
        boot.secureBoot = true;
        btrfs = {
          enable = true;
          impermanence.enable = true;
        };
        luks.remoteUnlock = true;
        network.wol.enable = true;
      };

      roles.nas = {
        backup.enable = true;
        glances.enable = true;
        power-notification.enable = true;
        plex.enable = true;
        syncthing.enable = true;
        tls.enable = true;
      };
    };

    powerManagement.powertop.enable = true;

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
          "valid users" = [
            "christian"
            "sophie"
          ];
          "guest account" = "nobody";
          "map to guest" = "bad user";
        };
        photo = {
          comment = "Photo Gallery";
          path = "/data/photo";
          browsable = "yes";
          writable = "yes";
          "create mask" = "0644";
          "directory mask" = "0755";
        };
        plex = {
          comment = "Plex Media";
          path = "/data/plex";
          browsable = "yes";
          writable = "yes";
          "create mask" = "0644";
          "directory mask" = "0755";
        };
        private = {
          comment = "Private File Sharing";
          path = "/data/share/private";
          browsable = "yes";
          writable = "yes";
          "create mask" = "0644";
          "directory mask" = "0755";
        };
        public = {
          comment = "Public File Sharing";
          path = "/data/share/public";
          browsable = "yes";
          writable = "yes";
          "guest ok" = "yes";
          "create mask" = "0644";
          "directory mask" = "0755";
        };
        homes = {
          browseable = "no";
          writable = "yes";
          "create mask" = "0600";
          "directory mask" = "0700";
          "valid users" = "%S";
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d /data/share/private 0755 root root -"
      "d /data/share/public 0755 root root -"
    ];
  };
}
