{
  config,
  lib,
  pkgs,
  ...
}:

let

  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.custom.roles.nas.plex;

  plexPort = "32400";
  threadfinPort = "34400";

  plexLocalUrl = "http://localhost:${plexPort}";
  threadfinLocalUrl = "http://localhost:${threadfinPort}";
  plexRemoteUrl = "https://${cfg.plexHost}";
  threadfinRemoteUrl = "https://${cfg.threadfinHost}/web";

  plexApiKeySecret = "dashboard-plex-api-key";

in

{
  options = {
    custom.roles.nas.plex = {
      enable = mkEnableOption "Plex config";

      plexHost = mkOption {
        type = types.str;
        default = "plex.local.harke.ch";
        description = "Host name where Plex is available on";
      };

      threadfinHost = mkOption {
        type = types.str;
        default = "threadfin.local.harke.ch";
        description = "Host name where Threadfin is available on";
      };
    };
  };

  config = mkIf cfg.enable {
    custom = {
      base = {
        agenix.secrets = [ plexApiKeySecret ];
        system.btrfs.impermanence.extraDirectories = [ config.services.plex.dataDir ];
      };
      roles = {
        backup.rsync.jobs.backup.excludes = [
          "/persist${config.services.plex.dataDir}/Plex Media Server/Cache"
          "${config.services.plex.dataDir}/Plex Media Server/Cache"
        ];
        nas.dashboard = {
          environment = "HOMEPAGE_FILE_PLEX_API_KEY=${config.age.secrets."${plexApiKeySecret}".path}";
          secrets = [ plexApiKeySecret ];
          services = [
            {
              Plex = {
                icon = "plex.svg";
                href = plexRemoteUrl;
                siteMonitor = plexLocalUrl;
                widget = {
                  url = plexLocalUrl;
                  type = "plex";
                  key = "{{HOMEPAGE_FILE_PLEX_API_KEY}}";
                };
              };
            }
            {
              Threadfin = {
                icon = "threadfin.svg";
                href = threadfinRemoteUrl;
                siteMonitor = threadfinLocalUrl;
              };
            }
          ];
        };
      };
    };

    services = {
      plex = {
        enable = true;
        dataDir = "/var/lib/plex";
        openFirewall = true;
        package = pkgs.unstable.plex;
      };

      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              plex.loadBalancer.servers = [ { url = plexLocalUrl; } ];
              threadfin.loadBalancer.servers = [ { url = threadfinLocalUrl; } ];
            };

            routers = {
              plex = {
                entryPoints = [ "websecure" ];
                rule = "Host(`${cfg.plexHost}`)";
                service = "plex";
                tls.certResolver = "letsencrypt";
              };
              threadfin = {
                entryPoints = [ "websecure" ];
                rule = "Host(`${cfg.threadfinHost}`)";
                service = "threadfin";
                tls.certResolver = "letsencrypt";
                middlewares = [ "authelia" ];
              };
            };
          };
        };
      };
    };

    users = {
      users = {
        # Grant access to render device (/dev/dri/renderD128).
        plex.extraGroups = [ "render" ];

        threadfin = {
          group = "threadfin";
          isSystemUser = true;
          uid = config.ids.uids.plex + 1;
        };
      };
      groups.threadfin = {
        gid = config.ids.gids.plex + 1;
      };
    };

    virtualisation.oci-containers =
      let
        uidStr = toString config.users.users.threadfin.uid;
        gidStr = toString config.users.groups.threadfin.gid;
      in
      {
        containers = {
          threadfin = {
            image = "fyb3roptik/threadfin:1.2.37-nvidia";
            ports = [ "127.0.0.1:${threadfinPort}:${threadfinPort}" ];
            environment = {
              PUID = uidStr;
              PGID = gidStr;
              TZ = "Europe/Zurich";
              NVIDIA_DRIVER_CAPABILITIES = "all";
              NVIDIA_VISIBLE_DEVICES = "all";
            };
            extraOptions = [
              "--gpus=all"
            ];
            user = "${uidStr}:${gidStr}";
            volumes = [
              "/data/container/threadfin/conf:/home/threadfin/conf"
              "${toString ./threadfin/playlists}:/home/threadfin/playlists"
            ];
          };
        };
      };
  };
}
