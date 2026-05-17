{ config, lib, ... }:

let

  cfg = config.custom.roles.nas.glances;

  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  inherit (lib.generators) toINI;

  localUrl = "http://localhost:${toString config.services.glances.port}";
  remoteUrl = "https://${cfg.host}";

in

{
  options = {
    custom.roles.nas.glances = {
      enable = mkEnableOption "Glances config";

      host = mkOption {
        type = types.str;
        default = "glances.local.harke.ch";
        description = "Host name where glances is available on";
      };
    };
  };

  config = mkIf cfg.enable {
    environment.etc."glances/glances.conf".text = toINI { } {
      global = {
        check_update = false;
      };
      diskio = {
        hide = "dm-.*,loop.*";
      };
      fs = {
        hide = "/etc/.*,/var/.*,/nix.*,/persist,/snapshots,/data/.*";
      };
    };

    custom.roles.nas.dashboard.services = [
      {
        Glances = {
          icon = "glances.svg";
          href = remoteUrl;
          siteMonitor = localUrl;
        };
      }
    ];

    services = {
      glances.enable = true;

      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              glances.loadBalancer.servers = [
                { url = localUrl; }
              ];
            };

            routers = {
              glances = {
                entryPoints = [ "websecure" ];
                rule = "Host(`${cfg.host}`)";
                service = "glances";
                tls.certResolver = "letsencrypt";
              };
            };
          };
        };
      };
    };
  };
}
