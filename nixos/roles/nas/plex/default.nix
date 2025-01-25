{ config, lib, ... }:

let

  inherit (lib) mkEnableOption mkIf;

  cfg = config.custom.roles.nas.plex;

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
      };

      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              plex.loadBalancer.servers = [ { url = "http://localhost:32400"; } ];
            };

            routers = {
              plex = {
                entryPoints = [ "websecure" ];
                rule = "Host(`plex.local.harke.ch`)";
                service = "plex";
              };
            };
          };
        };
      };
    };

    virtualisation.oci-containers =
      let
        workdirBase = "/data/containers";
      in
      {
        containers = {
          threadfin = {
            image = "fyb3roptik/threadfin:1.2.21";
            ports = [
              "34400:34400"
            ];
            environment = {
              PUID = "1001";
              PGID = "1001";
              TZ = "Europe/Zurich";
            };
            volumes = [
              "./data/conf:/home/threadfin/conf"
              "./data/playlists:/home/threadfin/playlists"
            ];
            workdir = "${workdirBase}/threadfin";
          };
        };
      };
  };
}
