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
        agenix.secrets = [ cloudflareDnsApiTokenSecret ];
      };
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

    security.acme = {
      acceptTerms = true;
      defaults = {
        email = "acme@harke.ch";
        server = "https://acme-staging-v02.api.letsencrypt.org/directory";
      };

      certs.${cfg.domain} = {
        inherit (cfg) domain;
        inherit (config.services.traefik) group;
        dnsProvider = "cloudflare";
        extraDomainNames = [ "*.${cfg.domain}" ];
        credentialFiles = {
          CLOUDFLARE_DNS_API_TOKEN_FILE = config.age.secrets.${cloudflareDnsApiTokenSecret}.path;
        };
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
