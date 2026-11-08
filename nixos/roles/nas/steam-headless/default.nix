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

  # The 2.x SHUI portal serves HTTPS with a self-signed cert on webPort;
  # the old PORT_NOVNC_WEB HTTP endpoint no longer exists.
  localSteamUrl = "https://localhost:${toString cfg.services.steam-headless.webPort}";
  localSunshineUrl = "https://localhost:${toString cfg.services.sunshine.port}";
  remoteSteamUrl = "https://${cfg.services.steam-headless.host}";
  remoteSunshineUrl = "https://${cfg.services.sunshine.host}";

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

      evdevInputs = mkEnableOption "virtual evdev input injection; requires /dev/uhid on the host";

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

          webPort = mkOption {
            type = types.int;
            default = 8483;
            description = "Port of the SHUI portal (self-signed TLS) proxied by traefik";
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
    custom.roles = {
      backup.rsync.jobs.backup.excludes = [
        "${cfg.dataPath}/home/*/.thumbnails/"
        "${cfg.dataPath}/home/*/.cache/"
        "${cfg.dataPath}/home/*/.config/*/Cache/"
        "${cfg.dataPath}/home/*/.local/share/flatpak/"
        "${cfg.dataPath}/home/*/.local/share/Trash/"
      ];
      nas.dashboard.services = [
        {
          Steam = {
            icon = "steam.svg";
            href = remoteSteamUrl;
            siteMonitor = localSteamUrl;
          };
          Sunshine = {
            icon = "steam.svg";
            href = remoteSunshineUrl;
            siteMonitor = localSunshineUrl;
          };
        }
      ];
    };

    users = {
      # Pin the ids: with an undeclared uid NixOS allocates one via
      # systemd-sysusers at activation, so `toString ...uid` below evaluates
      # to null and the container silently falls back to the image default 1000.
      users.steam-headless = {
        uid = 985;
        isSystemUser = true;
        group = "steam-headless";
      };

      groups.steam-headless = {
        gid = 982;
      };
    };

    virtualisation.oci-containers.containers.steam-headless = {
      image = "josh5/steam-headless:2";

      hostname = "steam-headless";

      # Mirrors the upstream devices-and-storage contract (steamheadless.com docs).
      capabilities = {
        DAC_READ_SEARCH = true;
        NET_ADMIN = true;
        SYS_ADMIN = true;
        SYS_NICE = true;
        SYS_PTRACE = true;
      };

      devices = [
        "/dev/fuse"
        "/dev/uinput"
      ]
      ++ (
        if cfg.evdevInputs then
          [
            "/dev/uhid"
          ]
        else
          [ ]
      );

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
        ENABLE_EVDEV_INPUTS = if cfg.evdevInputs then "true" else "false";
        NVIDIA_DRIVER_CAPABILITIES = "all";
        NVIDIA_VISIBLE_DEVICES = "all";

        PUID = toString config.users.users.steam-headless.uid;
        PGID = toString config.users.groups.steam-headless.gid;
        UMASK = "000";
        USER_PASSWORD = "password";
      };

      extraOptions = [
        "--gpus=all"
        "--security-opt=apparmor=unconfined"
        "--security-opt=seccomp=unconfined"
        # PID 1 of the image is systemd; without the writable cgroup, private
        # cgroup namespace and tmpfs set it aborts right after steam-headless-init.
        "--systemd=always"
        "--security-opt=systempaths=unconfined"
        "--tmpfs=/dev/input:rw,dev,mode=0755"
        "--ulimit=nofile=1024:524288"
        "--device-cgroup-rule=c 13:* rmw"
        "--ipc=host"
        "--add-host=steam-headless:127.0.0.1"
        "--memory=8g"
      ]
      # shinputd's unit lists /dev/uhid in InaccessiblePaths, which overmounts
      # an existing path: when the path is absent the unit dies (status 226/NAMESPACE)
      # and the Requires= chain in steam-headless-pre-session.target takes down the
      # whole session, even with ENABLE_EVDEV_INPUTS=false. Satisfy the path with
      # a bind file; only a real HID device (evdevInputs) enables injection.
      ++ (
        if cfg.evdevInputs then
          [ ]
        else
          [
            "--volume=${cfg.dataPath}/dev-uhid:/dev/uhid"
          ]
      );

      networks = [
        "host"
      ];

      # lol, --network=host because I can't be bothered to find all the ports anymore
      ports = [

      ];

      pull = "always";

      volumes = [
        # The image's desktop home is /home/steamheadless; per-container private,
        # must stay on a native Linux filesystem (Proton prefixes need POSIX).
        "${cfg.dataPath}/home:/home/steamheadless:rw"

        # Shared Steam library; /mnt/games/GameLibrary/Steam is registered as a
        # Steam storage library by the image itself at startup.
        "${cfg.dataPath}/games:/mnt/games:rw"

        # Private appliance state and journal; without them the image redoes
        # initial setup and refetches the compat32 cache on every recreation.
        "steam-headless-state:/var/lib/steam-headless"
        "steam-headless-journal:/var/log/journal"

        # shinputd reads kernel-allocated input device numbers here.
        "/sys/devices/virtual/input:/sys/devices/virtual/input:ro"
        "/etc/localtime:/run/host-localtime:ro"
      ];
    };

    networking.firewall = {
      enable = true;
      allowedTCPPorts = [
        7860
        5900
        8483
        32036
        32037
        32041
        47984
        47989
        48010
      ];
      allowedUDPPorts = [
        27031
        27036
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
              steam.loadBalancer = {
                servers = [ { url = localSteamUrl; } ];
                serversTransport = "steam-transport";
              };

              sunshine.loadBalancer = {
                servers = [ { url = localSunshineUrl; } ];
                serversTransport = "sunshine-transport";
              };
            };

            # Skip TLS verification for both self-signed container backends
            serversTransports = {
              sunshine-transport.insecureSkipVerify = true;
              steam-transport.insecureSkipVerify = true;
            };

            routers = {
              steam = {
                entryPoints = [ "websecure" ];
                rule = "Host(`${cfg.services.steam-headless.host}`)";
                service = "steam";
                tls.certResolver = "letsencrypt";
                middlewares = [ "authelia" ];
              };

              # 2.44 syncs Sunshine credentials through SHUI enrolment; clients
              # pair via the SHUI dashboard, so no basic-auth injection applies.
              sunshine = {
                entryPoints = [ "websecure" ];
                rule = "Host(`${cfg.services.sunshine.host}`)";
                service = "sunshine";
                tls.certResolver = "letsencrypt";
                middlewares = [
                  "authelia"
                ];
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
      # Placeholder bind source for /dev/uhid (see extraOptions above).
      "f ${cfg.dataPath}/dev-uhid 0600 ${config.users.users.steam-headless.name} ${config.users.users.steam-headless.group} -"
    ];
  };
}
