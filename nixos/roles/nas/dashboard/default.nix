{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.nas.dashboard;

  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  localUrl = "http://localhost:${toString config.services.homepage-dashboard.listenPort}";

  settingsFormat = pkgs.formats.yaml { };

in

{
  options = {
    custom.roles.nas.dashboard = {
      enable = mkEnableOption "dashboard service";

      host = mkOption {
        type = types.str;
        default = "dash.local.harke.ch";
        readOnly = true;
        description = "Host name (hardcoded)";
      };

      services = lib.mkOption {
        inherit (settingsFormat) type;
        description = ''
          Homepage services configuration.

          See <https://gethomepage.dev/configs/services/>.
        '';
        # Defaults: https://github.com/gethomepage/homepage/blob/main/src/skeleton/services.yaml
        example = [
          {
            "My First Group" = [
              {
                "My First Service" = {
                  href = "http://localhost/";
                  description = "Homepage is awesome";
                };
              }
            ];
          }
          {
            "My Second Group" = [
              {
                "My Second Service" = {
                  href = "http://localhost/";
                  description = "Homepage is the best";
                };
              }
            ];
          }
        ];
        default = [ ];
      };
    };
  };

  config = mkIf cfg.enable {

    services = {
      homepage-dashboard.enable = true;
      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              dashboard = {
                loadBalancer.servers = [
                  { url = localUrl; }
                ];
              };
            };

            routers = {
              dashboard = {
                entryPoints = [ "websecure" ];
                rule = "Host(`${config.custom.roles.nas.dashboard.host}`)";
                service = "dashboard";
                tls.certResolver = "letsencrypt";
                middlewares = [
                  "authelia"
                  "dashboard-hostheader"
                ];
              };
            };

            middlewares = {
              dashboard-hostheader = {
                headers = {
                  customRequestHeaders = {
                    Host = localUrl;
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
