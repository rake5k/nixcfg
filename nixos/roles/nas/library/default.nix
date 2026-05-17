{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.nas.library;

  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  localUrl = "http://localhost:${toString config.services.calibre-web.listen.port}";
  remoteUrl = "https://${cfg.host}";

  dashboardUsernameSecret = "dashboard-calibreweb-username";
  dashboardPasswordSecret = "dashboard-calibreweb-password";

in

{
  options = {
    custom.roles.nas.library = {
      enable = mkEnableOption "E-Book library";

      host = mkOption {
        type = types.str;
        default = "library.local.harke.ch";
        description = "Host name where the e-Book library is available on";
      };

      libraryPath = mkOption {
        type = types.path;
        default = "/data/library";
        description = "Path where the library data lies";
      };
    };
  };

  config = mkIf cfg.enable {
    custom = {
      base = {
        agenix.secrets = [
          dashboardUsernameSecret
          dashboardPasswordSecret
        ];
        system.btrfs.impermanence.extraDirectories = [
          "/var/lib/${config.services.calibre-web.dataDir}"
        ];
      };
      roles.nas.dashboard = {
        environment = ''
          HOMEPAGE_FILE_CALIBREWEB_USERNAME=${config.age.secrets."${dashboardUsernameSecret}".path}
          HOMEPAGE_FILE_CALIBREWEB_PASSWORD=${config.age.secrets."${dashboardPasswordSecret}".path}
        '';
        secrets = [
          dashboardUsernameSecret
          dashboardPasswordSecret
        ];
        services = [
          {
            Calibre-Web = {
              icon = "calibre-web.svg";
              href = remoteUrl;
              siteMonitor = localUrl;
              widget = {
                url = localUrl;
                type = "calibreweb";
                username = "{{HOMEPAGE_FILE_CALIBREWEB_USERNAME}}";
                password = "{{HOMEPAGE_FILE_CALIBREWEB_PASSWORD}}";
              };
            };
          }
        ];
      };
    };

    services = {
      calibre-web = {
        enable = true;
        package = pkgs.unstable.calibre-web;
        options = {
          calibreLibrary = cfg.libraryPath;
          enableBookConversion = true;
          enableBookUploading = true;
        };
      };

      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              library.loadBalancer.servers = [
                { url = localUrl; }
              ];
            };

            routers = {
              library = {
                entryPoints = [ "websecure" ];
                rule = "Host(`${cfg.host}`)";
                service = "library";
                tls.certResolver = "letsencrypt";
                middlewares = [ "authelia" ];
              };
            };
          };
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.libraryPath} 0755 ${config.services.calibre-web.user} ${config.services.calibre-web.group} -"
    ];
  };
}
