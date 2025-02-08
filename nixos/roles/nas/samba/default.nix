{ config, lib, ... }:

let

  cfg = config.custom.roles.nas.samba;

  inherit (config.custom.base) hostname;
  inherit (lib) mkEnableOption mkIf;

  shareBaseFolder = "/data/share";
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
          "create mask" = "0644";
          "directory mask" = "0755";
          "valid users" = defaultValidUsers;
        };

        plex = {
          comment = "Plex Media";
          path = "/data/plex";
          browsable = "yes";
          writable = "yes";
          "create mask" = "0644";
          "directory mask" = "0755";
          "valid users" = defaultValidUsers;
        };

        private = {
          comment = "Private File Sharing";
          path = "${shareBaseFolder}/private";
          browsable = "yes";
          writable = "yes";
          "create mask" = "0644";
          "directory mask" = "0755";
          "valid users" = defaultValidUsers;
        };

        public = {
          comment = "Public File Sharing";
          path = "${shareBaseFolder}/public";
          browsable = "yes";
          writable = "yes";
          "guest ok" = "yes";
          "create mask" = "0644";
          "directory mask" = "0755";
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d ${shareBaseFolder}/private 0755 root root -"
      "d ${shareBaseFolder}/public 0777 root root -"
    ];
  };
}
