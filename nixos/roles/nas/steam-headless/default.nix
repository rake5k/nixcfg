# based on https://github.com/christian-blades-cb/dots/blob/55036e3a642a8aba3c10ee2342424581bf350a15/nixos/steam-headless-container.nix#L44

{ config, lib, ... }:

let

  cfg = config.custom.roles.nas.steam-headless;

  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

in

{
  options = {
    custom.roles.nas.steam-headless = {
      enable = mkEnableOption "Steam-Headless config";

      dataPath = mkOption {
        type = types.path;
        default = "/data/container/steam-headless";
        description = "Path where the Sunshine data lies";
      };

      services = {
        steam-headless = {
          host = mkOption {
            type = types.str;
            default = "steam.local.harke.ch";
            description = "Host name where steam-headless web UI is available on";
          };

          port = mkOption {
            type = types.int;
            default = 8083;
            description = "Port of the steam-headless web UI";
          };
        };

        sunshine = {
          host = mkOption {
            type = types.str;
            default = "sunshine.local.harke.ch";
            description = "Host name where sunshine web UI is available on";
          };

          port = mkOption {
            type = types.int;
            default = 47990;
            description = "Port of the sunshine web UI";
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {

    users = {
      users.steam-headless = {
        isSystemUser = true;
        group = "steam-headless";
      };

      groups.steam-headless = { };
    };

    virtualisation.oci-containers.containers.steam-headless = {
      image = "josh5/steam-headless:latest";

      # lol, --network=host because I can't be bothered to find all the ports anymore
      ports = [

      ];

      hostname = "steam-headless";

      extraOptions = [
        "--gpus=all"
        "--security-opt=apparmor=unconfined"
        "--security-opt=seccomp=unconfined"
        "--device=/dev/uinput"
        "--device=/dev/fuse"
        "--device-cgroup-rule=c 13:* rmw"
        "--cap-add=NET_ADMIN"
        "--cap-add=SYS_ADMIN"
        "--cap-add=SYS_NICE"
        "--ipc=host"
        "--add-host=steam-headless:127.0.0.1"
        "--network=host"
        "--memory=8g"
      ];

      volumes = [
        "${cfg.dataPath}/home:/home/default:rw"
        "${cfg.dataPath}/games:/mnt/games:rw"
      ];

      # https://github.com/Steam-Headless/docker-steam-headless/blob/master/docs/compose-files/.env
      environment = {
        NAME = "SteamHeadless";
        TZ = "Europe/Zurich";
        USER_LOCALES = "de_CH.UTF-8 UTF-8";
        DISPLAY = ":55";
        MODE = "primary";
        WEB_UI_MODE = "vnc";
        ENABLE_VNC_AUDIO = "true";
        PORT_NOVNC_WEB = toString cfg.services.steam-headless.port;
        ENABLE_STEAM = "true";
        #STEAM_ARGS = "-silent -bigpicture";
        ENABLE_SUNSHINE = "true";
        SUNSHINE_USER = "sunshine";
        SUNSHINE_PASS = "sunshine";
        ENABLE_EVDEV_INPUTS = "true";
        NVIDIA_DRIVER_CAPABILITIES = "all";
        NVIDIA_VISIBLE_DEVICES = "all";

        PUID = toString config.users.users.steam-headless.uid;
        PGID = toString config.users.groups.steam-headless.gid;
        UMASK = "000";
        USER_PASSWORD = "password";
      };
    };

    networking.firewall = {
      enable = true;
      allowedTCPPorts = [
        7860
        5900
        cfg.services.steam-headless.port
        32036
        32037
        32041
        47984
        47989
        cfg.services.sunshine.port
        48010
      ];
      allowedUDPPorts = [
        47998
        47999
        48000
        48002
        48010
      ];
    };

    services = {
      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              steam.loadBalancer.servers = [
                { url = "http://localhost:${toString cfg.services.steam-headless.port}"; }
              ];

              sunshine.loadBalancer.servers = [
                { url = "http://localhost:${toString cfg.services.sunshine.port}"; }
              ];
            };

            routers = {
              steam = {
                entryPoints = [ "websecure" ];
                rule = "Host(`${cfg.services.steam-headless.host}`)";
                service = "steam";
                tls.certResolver = "letsencrypt";
              };

              sunshine = {
                entryPoints = [ "websecure" ];
                rule = "Host(`${cfg.services.sunshine.host}`)";
                service = "sunshine";
                tls.certResolver = "letsencrypt";
              };
            };
          };
        };
      };

      udev.extraRules = ''
        KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess"
      '';
    };

    # this container expects some host directories to exist for persistence, let's automate that
    #systemd.services.steam-headless-init = {
    #  enable = true;

    #  wantedBy = [
    #    "${config.virtualisation.oci-containers.backend}-steam-headless.service"
    #  ];

    #  script = ''
    #    umask 077
    #    mkdir -p /var/lib/steam-headless/{home,.X11-unix,pulse,games}
    #    umask 066
    #  '';

    #  serviceConfig = {
    #    User = "steam-headless";
    #    Group = "steam-headless";
    #    Type = "oneshot";
    #    RemainAfterExit = true;
    #    StateDirectory = "steam-headless";
    #    StateDirectoryMode = "0700";
    #  };
    #};

    systemd.tmpfiles.rules = [
      "d ${cfg.dataPath}/home 0755 ${config.users.users.steam-headless.name} ${config.users.users.steam-headless.group} -"
      "d ${cfg.dataPath}/games 0755 ${config.users.users.steam-headless.name} ${config.users.users.steam-headless.group} -"
    ];
  };
}
