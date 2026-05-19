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

  oauthEnvSecret = "open-webui-oauth-env";

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
    custom = {
      base.agenix.secrets = [ oauthEnvSecret ];
      roles = {
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

      open-webui = {
        environment = {
          WEBUI_URL = remoteUrl;
          ENABLE_OAUTH_SIGNUP = "true";
          ENABLE_OAUTH_PERSISTENT_CONFIG = "false";
          OAUTH_MERGE_ACCOUNTS_BY_EMAIL = "true";
          OAUTH_PROVIDER_NAME = "Authelia";
          OPENID_PROVIDER_URL = "https://${config.custom.roles.nas.authelia.host}/.well-known/openid-configuration";
          OAUTH_CLIENT_ID = "open-webui";
          OAUTH_SCOPES = "openid profile email groups";
          OAUTH_CODE_CHALLENGE_METHOD = "S256";
          ENABLE_OAUTH_ROLE_MANAGEMENT = "true";
          OAUTH_ROLES_CLAIM = "groups";
          OAUTH_ALLOWED_ROLES = "users";
          OAUTH_ADMIN_ROLES = "admins";
        };
        environmentFile = config.age.secrets."${oauthEnvSecret}".path;
      };
    };
  };
}
