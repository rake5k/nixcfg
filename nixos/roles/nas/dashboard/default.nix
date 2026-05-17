{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.nas.dashboard;

  inherit (lib)
    genAttrs
    mkEnableOption
    mkForce
    mkIf
    mkOption
    types
    ;

  settingsFormat = pkgs.formats.yaml { };

  user = "homepage-dashboard";
  mkSecretOwner =
    secrets:
    genAttrs secrets (_name: {
      owner = user;
    });
  sortByAttrName =
    list:
    builtins.sort (
      a: b: (builtins.head (builtins.attrNames a)) < (builtins.head (builtins.attrNames b))
    ) list;

  localUrl = "http://localhost:${toString config.services.homepage-dashboard.listenPort}";
  openweathermapKeySecret = "dashboard-openweathermap-key";
  openweathermapKeySecretPath = config.age.secrets."${openweathermapKeySecret}".path;
  synologyDsmUsernameSecret = "dashboard-synology-dsm-username";
  synologyDsmPasswordSecret = "dashboard-synology-dsm-password";
  synologyDsmUsernameSecretPath = config.age.secrets."${synologyDsmUsernameSecret}".path;
  synologyDsmPasswordSecretPath = config.age.secrets."${synologyDsmPasswordSecret}".path;

in

{
  options = {
    custom.roles.nas.dashboard = {
      enable = mkEnableOption "dashboard service";

      environment = mkOption {
        type = types.lines;
        default = "";
        description = "Environment to reference secrets in config.";
      };

      host = mkOption {
        type = types.str;
        default = "dash.local.harke.ch";
        readOnly = true;
        description = "Host name (hardcoded)";
      };

      secrets = mkOption {
        type = with types; listOf str;
        default = [ ];
        description = "Names of secrets that homepage needs access to.";
      };

      services = mkOption {
        inherit (settingsFormat) type;
        description = ''
          Homepage services configuration.

          See <https://gethomepage.dev/configs/services/>.
        '';
        # Defaults: https://github.com/gethomepage/homepage/blob/main/src/skeleton/services.yaml
        example = [
          {
            "My First Service" = {
              href = "http://localhost/";
              description = "Homepage is awesome";
            };
          }
          {
            "My Second Service" = {
              href = "http://localhost/";
              description = "Homepage is the best";
            };
          }
        ];
        default = [ ];
      };
    };
  };

  config = mkIf cfg.enable {

    custom.base.agenix.secrets = [
      openweathermapKeySecret
      synologyDsmUsernameSecret
      synologyDsmPasswordSecret
    ];
    age.secrets = mkSecretOwner (
      cfg.secrets
      ++ [
        openweathermapKeySecret
        synologyDsmUsernameSecret
        synologyDsmPasswordSecret
      ]
    );

    services = {
      homepage-dashboard = {
        enable = true;

        bookmarks = [
          {
            Network = [
              {
                Printer = [
                  {
                    icon = "si-hp.svg";
                    href = "https://pr-hp-chr/";
                  }
                ];
              }
              {
                OPNsense = [
                  {
                    icon = "opnsense.svg";
                    href = "https://fw-opnsense-1/";
                  }
                ];
              }
              {
                "UniFi Controller" = [
                  {
                    icon = "unifi.svg";
                    href = "https://unifi/";
                  }
                ];
              }
            ];
          }
        ];

        environmentFile = toString (
          pkgs.writeText "homepage-dashboard-env" ''
            HOMEPAGE_FILE_OPENWEATHERMAP_KEY=${openweathermapKeySecretPath}
            HOMEPAGE_FILE_SYNOLOGY_DSM_USERNAME=${synologyDsmUsernameSecretPath}
            HOMEPAGE_FILE_SYNOLOGY_DSM_PASSWORD=${synologyDsmPasswordSecretPath}
            ${cfg.environment}
          ''
        );

        services = [
          {
            "Home Server" = sortByAttrName cfg.services;
          }
          {
            NAS = [
              {
                "Active Backup for Business" = {
                  icon = "synology.svg";
                  href = "https://sv-syno-01:5001/?launchApp=SYNO.SDS.ActiveBackupPortal.Application";
                  siteMonitor = "https://sv-syno-01:5001/?launchApp=SYNO.SDS.ActiveBackupPortal.Application";
                };
              }
              {
                "Synology Disk Station" = {
                  icon = "synology-dsm.svg";
                  href = "https://sv-syno-01:5001/";
                  siteMonitor = "https://sv-syno-01:5001/";
                  widget = {
                    type = "diskstation";
                    url = "https://sv-syno-01:5001";
                    username = "{{HOMEPAGE_FILE_SYNOLOGY_DSM_USERNAME}}";
                    password = "{{HOMEPAGE_FILE_SYNOLOGY_DSM_PASSWORD}}";
                    volume = "volume_1";
                  };
                };
              }
            ];
          }
        ];

        settings = {
          title = "Home Server";
          color = "stone";
          providers = {
            openweathermap = "{{HOMEPAGE_FILE_OPENWEATHERMAP_KEY}}";
            weatherapi = "weatherapiapikey";
          };
        };

        widgets = [
          {
            openweathermap = {
              latitude = "46.939281";
              longitude = "7.784216";
              units = "metric"; # or imperial
              provider = "openweathermap";
              cache = 5; # Time in minutes to cache API responses, to stay within limits
              format = {
                maximumFractionDigits = 1;
              };
            };
          }

          {
            resources = {
              cpu = true;
              memory = true;
              cputemp = true;
              uptime = true;
              disk = [
                "/"
                "/data"
              ];
              network = true;
              label = "Hyperion";
            };
          }

          {
            search = {
              provider = "custom";
              url = "https://search.harke.ch/search?q=";
              target = "_blank";
              suggestionUrl = "https://duckduckgo.com/ac/?type=list&q=";
              showSearchSuggestions = true;
            };
          }
        ];
      };

      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              dashboard = {
                loadBalancer.servers = [
                  { url = localUrl; }
                ];
              };
            };

            routers = {
              dashboard = {
                entryPoints = [ "websecure" ];
                rule = "Host(`${cfg.host}`)";
                service = "dashboard";
                tls.certResolver = "letsencrypt";
                middlewares = [ "dashboard-hostheader" ];
              };
            };

            middlewares = {
              dashboard-hostheader = {
                headers = {
                  customRequestHeaders = {
                    Host = "localhost:${toString config.services.homepage-dashboard.listenPort}";
                  };
                };
              };
            };
          };
        };
      };
    };

    systemd.services.homepage-dashboard.serviceConfig = {
      User = user;
      Group = user;
      DynamicUser = mkForce false;
    };

    users = {
      users."${user}" = {
        isSystemUser = true;
        group = user;
      };
      groups."${user}" = { };
    };
  };
}
