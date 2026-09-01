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

  dashboardCfg = config.custom.roles.nas.dashboard;
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
        # Calibre-Web compares both OPDS credentials verbatim, so a decrypted
        # trailing newline would never match the account.
        environment = ''
          HOMEPAGE_FILE_CALIBREWEB_USERNAME=${dashboardCfg.trimmedSecretsPath}/${dashboardUsernameSecret}
          HOMEPAGE_FILE_CALIBREWEB_PASSWORD=${dashboardCfg.trimmedSecretsPath}/${dashboardPasswordSecret}
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
          # Trust Authelia's forward-auth Remote-User header for SSO login.
          reverseProxyAuth = {
            enable = true;
            header = "Remote-User";
          };
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
