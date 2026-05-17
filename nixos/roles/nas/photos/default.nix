{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.nas.photos;

  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  localUrl = "http://localhost:${toString config.services.immich.port}";
  remoteUrl = "https://${cfg.host}";

  immichApiKeySecret = "dashboard-immich-api-key";

in

{
  options = {
    custom.roles.nas.photos = {
      enable = mkEnableOption "Photo gallery";

      host = mkOption {
        type = types.str;
        default = "photos.local.harke.ch";
        description = "Host name where the photo gallery is available on";
      };

      mediaPath = mkOption {
        type = types.path;
        default = "/data/photo";
        description = "Path where the photo gallery data lies";
      };
    };
  };

  config = mkIf cfg.enable {
    custom = {
      base = {
        agenix.secrets = [ immichApiKeySecret ];
        system.btrfs.impermanence.extraDirectories = [
          "/var/lib/${config.services.postgresql.dataDir}"
        ];
      };
      roles.nas.dashboard = {
        environment = "HOMEPAGE_FILE_IMMICH_API_KEY=${config.age.secrets."${immichApiKeySecret}".path}";
        secrets = [ immichApiKeySecret ];
        services = [
          {
            Immich = {
              icon = "immich.svg";
              href = remoteUrl;
              siteMonitor = localUrl;
              widget = {
                url = localUrl;
                type = "immich";
                key = "{{HOMEPAGE_FILE_IMMICH_API_KEY}}";
                version = 2;
              };
            };
          }
        ];
      };
    };

    environment.systemPackages = [ pkgs.immich-cli ];

    fileSystems = {
      "/mnt/syno-photo" = {
        device = "sv-syno-01:/volume1/photo";
        fsType = "nfs";
        options = [
          "x-systemd.automount"
          "noauto"
          "x-systemd.idle-timeout=60"
          "x-systemd.device-timeout=5s"
          "x-systemd.mount-timeout=5s"
        ];
      };
    };

    services = {
      immich = {
        enable = true;
        # `null` will give access to all devices:
        accelerationDevices = null;
        mediaLocation = cfg.mediaPath;
        settings = {
          machineLearning.facialRecognition.minFaces = 15;
          server.externalDomain = remoteUrl;
        };
      };

      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              photos.loadBalancer.servers = [
                { url = localUrl; }
              ];
            };

            routers = {
              photos = {
                entryPoints = [ "websecure" ];
                rule = "Host(`${cfg.host}`)";
                service = "photos";
                tls.certResolver = "letsencrypt";
              };
            };
          };
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.mediaPath} 0755 ${config.services.immich.user} ${config.services.immich.group} -"
    ];

    users.users."${config.services.immich.user}".extraGroups = [
      "video"
      "render"
    ];
  };
}
