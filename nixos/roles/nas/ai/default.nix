{ config, lib, ... }:

let

  cfg = config.custom.roles.nas.ai;

  inherit (lib) mkEnableOption mkIf;

in

{
  options = {
    custom.roles.nas.ai = {
      enable = mkEnableOption "AI services";
    };
  };

  config = mkIf cfg.enable {
    custom.roles.ai = {
      text.enable = true;
    };

    services = {
      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              ollama.loadBalancer.servers = [
                { url = "http://localhost:${toString config.services.ollama.port}"; }
              ];

              open-webui.loadBalancer.servers = [
                { url = "http://localhost:${toString config.services.open-webui.port}"; }
              ];
            };

            routers = {
              ollama = {
                entryPoints = [ "websecure" ];
                middlewares = [ "hostheader" ];
                rule = "Host(`ollama.local.harke.ch`)";
                service = "ollama";
                tls.certResolver = "letsencrypt";
              };

              open-webui = {
                entryPoints = [ "websecure" ];
                rule = "Host(`chat.local.harke.ch`)";
                service = "open-webui";
                tls.certResolver = "letsencrypt";
              };
            };

            middlewares = {
              hostheader = {
                headers = {
                  customRequestHeaders = {
                    Host = "localhost:11434";
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
