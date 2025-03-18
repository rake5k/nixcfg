{ config, lib, ... }:

let

  cfg = config.custom.roles.nas.library;

  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

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
    custom.base.system.btrfs.impermanence.extraDirectories = [
      "/var/lib/${config.services.calibre-web.dataDir}"
    ];

    services = {
      calibre-web = {
        enable = true;
        openFirewall = true;
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
                { url = "http://localhost:${toString config.services.calibre-web.listen.port}"; }
              ];
            };

            routers = {
              library = {
                entryPoints = [ "websecure" ];
                rule = "Host(`${cfg.host}`)";
                service = "library";
                tls.certResolver = "letsencrypt";
              };
            };
          };
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.libraryPath} 0755 root root -"
    ];
  };
}
