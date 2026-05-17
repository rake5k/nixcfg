{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.nas.ai;

  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  localUrl = "http://localhost:${toString config.services.open-webui.port}";
  localOllamaUrl = "http://localhost:${toString config.services.ollama.port}";
  remoteUrl = "https://${cfg.openWebuiHost}";
  remoteOllamaUrl = "https://${cfg.ollamaHost}";

in

{
  options = {
    custom.roles.nas.ai = {
      enable = mkEnableOption "AI services";

      ollamaHost = mkOption {
        type = types.str;
        default = "ollama.local.harke.ch";
        description = "Host name where the Ollama API is available on";
      };

      openWebuiHost = mkOption {
        type = types.str;
        default = "chat.local.harke.ch";
        description = "Host name where Open WebUI is available on";
      };
    };
  };

  config = mkIf cfg.enable {
    custom.roles = {
      ai.text.enable = true;
      nas.dashboard.services = [
        {
          "Open WebUI" = {
            icon = "open-webui.svg";
            href = remoteUrl;
            siteMonitor = localUrl;
          };
        }
        {
          "Ollama" = {
            icon = "ollama.svg";
            href = remoteOllamaUrl;
            siteMonitor = localOllamaUrl;
          };
        }
      ];
    };

    environment.systemPackages = with pkgs; [ unstable.llmfit ];

    services = {
      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              ollama.loadBalancer.servers = [
                { url = localOllamaUrl; }
              ];

              open-webui.loadBalancer.servers = [
                { url = localUrl; }
              ];
            };

            routers = {
              ollama = {
                entryPoints = [ "websecure" ];
                middlewares = [ "ollama-hostheader" ];
                rule = "Host(`${cfg.ollamaHost}`)";
                service = "ollama";
                tls.certResolver = "letsencrypt";
              };

              open-webui = {
                entryPoints = [ "websecure" ];
                rule = "Host(`${cfg.openWebuiHost}`)";
                service = "open-webui";
                tls.certResolver = "letsencrypt";
              };
            };

            middlewares = {
              ollama-hostheader = {
                headers = {
                  customRequestHeaders = {
                    Host = "localhost:${toString config.services.ollama.port}";
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
