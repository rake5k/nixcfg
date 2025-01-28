{
  config,
  lib,
  pkgs,
  ...
}:

let

  inherit (lib) mkEnableOption mkIf;

  cfg = config.custom.roles.nas.plex;

  threadfinPort = "34400";

in

{
  options = {
    custom.roles.nas.plex = {
      enable = mkEnableOption "Plex config";
    };
  };

  config = mkIf cfg.enable {
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
              plex.loadBalancer.servers = [ { url = "http://localhost:32400"; } ];
              threadfin.loadBalancer.servers = [ { url = "http://localhost:${threadfinPort}"; } ];
            };

            routers = {
              plex = {
                entryPoints = [ "websecure" ];
                rule = "Host(`plex.local.harke.ch`)";
                service = "plex";
                tls.certResolver = "letsencrypt";
              };
              threadfin = {
                entryPoints = [ "websecure" ];
                rule = "Host(`threadfin.local.harke.ch`)";
                service = "threadfin";
                tls.certResolver = "letsencrypt";
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
            image = "fyb3roptik/threadfin:1.2.26";
            ports = [ "127.0.0.1:${threadfinPort}:${threadfinPort}" ];
            environment = {
              PUID = uidStr;
              PGID = gidStr;
              TZ = "Europe/Zurich";
            };
            user = "${uidStr}:${gidStr}";
            volumes = [
              "/data/containers/threadfin/conf:/home/threadfin/conf"
              "${toString ./threadfin/playlists}:/home/threadfin/playlists"
            ];
          };
        };
      };
  };
}
