{ config, lib, ... }:

let

  cfg = config.custom.roles.nas.dms;

  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

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
    custom.base.system.btrfs.impermanence.extraDirectories = [
      config.services.paperless.dataDir
    ];

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
        };
      };

      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              dms.loadBalancer.servers = [
                { url = "http://localhost:${toString config.services.paperless.port}"; }
              ];
            };

            routers = {
              dms = {
                entryPoints = [ "websecure" ];
                rule = "Host(`${cfg.host}`)";
                service = "dms";
                tls.certResolver = "letsencrypt";
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
