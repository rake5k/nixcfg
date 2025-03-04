{ config, lib, ... }:

let

  cfg = config.custom.roles.nas.tls;

  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  certificateDir = "/var/lib/acme/${cfg.domain}";
  cloudflareDnsApiTokenSecret = "cloudflare-api-key";

in

{
  options = {
    custom.roles.nas.tls = {
      enable = mkEnableOption "TLS termination for services";

      domain = mkOption {
        type = types.str;
        default = "local.harke.ch";
        description = "The domain where the services shall be hosted under.";
      };
    };
  };

  config = mkIf cfg.enable {
    custom = {
      base = {
        agenix.secrets = [
          cloudflareDnsApiTokenSecret
        ];
      };
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

    systemd.services.traefik = {
      serviceConfig = {
        EnvironmentFile = [ config.age.secrets.${cloudflareDnsApiTokenSecret}.path ];
      };
    };

    services.traefik = {
      enable = true;

      staticConfigOptions = {
        global = {
          checkNewVersion = false;
          sendAnonymousUsage = false;
        };

        log = {
          level = "INFO";
          filePath = "/var/log/traefik/traefik.log";
          format = "json";
          noColor = false;
          maxSize = 100;
          compress = true;
        };

        accessLog = {
          addInternals = true;
          filePath = "/var/log/traefik/access.log";
          bufferingSize = 100;
          fields = {
            names = {
              StartUTC = "drop";
            };
          };
          filters = {
            statusCodes = [
              "204-299"
              "400-499"
              "500-599"
            ];
          };
        };

        api = {
          dashboard = true;
        };

        certificatesResolvers = {
          letsencrypt = {
            acme = {
              email = "acme@harke.ch";
              storage = "/var/lib/traefik/cert.json";
              dnsChallenge = {
                provider = "cloudflare";
                disablePropagationCheck = true;
                delayBeforeCheck = "100s";
              };
            };
          };
        };

        entryPoints = {
          web = {
            address = ":80";
            http.redirections.entryPoint = {
              to = "websecure";
              scheme = "https";
              permanent = true;
            };
          };

          websecure = {
            address = ":443";
            http.tls = {
              certResolver = "letsencrypt";
              domains = [
                {
                  main = cfg.domain;
                  sans = [ "*.${cfg.domain}" ];
                }
              ];
            };
          };
        };
      };

      dynamicConfigOptions = {
        tls = {
          stores.default = {
            defaultCertificate = {
              certFile = "${certificateDir}/cert.pem";
              keyFile = "${certificateDir}/key.pem";
            };
          };

          certificates = [
            {
              certFile = "${certificateDir}/cert.pem";
              keyFile = "${certificateDir}/key.pem";
              stores = "default";
            }
          ];
        };
      };
    };
  };
}
