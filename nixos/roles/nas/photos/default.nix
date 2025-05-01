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
    custom.base.system.btrfs.impermanence.extraDirectories = [
      "/var/lib/${config.services.postgresql.dataDir}"
    ];

    environment.systemPackages = [ pkgs.immich-cli ];

    services = {
      immich = {
        enable = true;
        openFirewall = true;
        mediaLocation = cfg.mediaPath;
        settings = {
          machineLearning.facialRecognition.minFaces = 10;
          server.externalDomain = "https://${cfg.host}";
        };
      };

      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              photos.loadBalancer.servers = [
                { url = "http://localhost:${toString config.services.immich.port}"; }
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
  };
}
