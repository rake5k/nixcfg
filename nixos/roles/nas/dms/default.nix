{ config, lib, ... }:

let

  cfg = config.custom.roles.nas.dms;

  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  localUrl = "http://localhost:${toString config.services.paperless.port}";
  remoteUrl = "https://dms.local.harke.ch/";

  paperlessNgxKeySecret = "dashboard-paperless-ngx-key";

in

{
  options = {
    custom.roles.nas.dms = {
      enable = mkEnableOption "Document Management System";

      host = mkOption {
        type = types.str;
        default = "dms.local.harke.ch";
        description = "Host name where the DMS is available on";
      };

      docsPath = mkOption {
        type = types.path;
        default = "/data/dms";
        description = "Path where the document data lies";
      };
    };
  };

  config = mkIf cfg.enable {
    custom = {
      base = {
        agenix.secrets = [ paperlessNgxKeySecret ];
        system.btrfs.impermanence.extraDirectories = [
          config.services.paperless.dataDir
        ];
      };
      roles.nas.dashboard = {
        environment = "HOMEPAGE_FILE_PAPERLESS_NGX_KEY=${
          config.age.secrets."${paperlessNgxKeySecret}".path
        }";
        secrets = [ paperlessNgxKeySecret ];
        services = [
          {
            Paperless = {
              icon = "paperless-ngx.svg";
              href = remoteUrl;
              siteMonitor = localUrl;
              widget = {
                url = localUrl;
                type = "paperlessngx";
                key = "{{HOMEPAGE_FILE_PAPERLESS_NGX_KEY}}";
              };
            };
          }
        ];
      };
    };

    services = {
      paperless = {
        enable = true;
        domain = cfg.host;
        mediaDir = cfg.docsPath;
        settings = {
          PAPERLESS_CONSUMER_IGNORE_PATTERN = [
            ".DS_STORE/*"
            "desktop.ini"
          ];
          PAPERLESS_OCR_LANGUAGE = "deu+eng";

          # Authelia integration
          PAPERLESS_ENABLE_HTTP_REMOTE_USER = true;
          PAPERLESS_HTTP_REMOTE_USER_HEADER_NAME = "HTTP_REMOTE_USER";
          PAPERLESS_LOGOUT_REDIRECT_URL = "https://auth.local.harke.ch/logout";
        };
      };

      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              dms.loadBalancer.servers = [
                { url = localUrl; }
              ];
            };

            routers = {
              dms = {
                entryPoints = [ "websecure" ];
                rule = "Host(`${cfg.host}`)";
                service = "dms";
                tls.certResolver = "letsencrypt";
                middlewares = [ "authelia" ];
              };
            };
          };
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.docsPath} 0755 ${config.services.paperless.user} ${config.services.paperless.user} -"
    ];
  };
}
