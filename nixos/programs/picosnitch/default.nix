{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.programs.picosnitch;

  inherit (lib)
    getExe
    literalExpression
    mkEnableOption
    mkIf
    mkOption
    recursiveUpdate
    types
    versionAtLeast
    ;

  tomlFormat = pkgs.formats.toml { };

  group = "picosnitch";

  stateDir = "/var/lib/picosnitch";
  logDir = "/var/log/picosnitch";

  # The daemon gives the live event socket and the database files to
  # `data.group`, which is what lets the dashboard read them without being
  # root. Anything set in `settings` still wins.
  settings = recursiveUpdate { data.group = group; } cfg.settings;

in

{
  options = {
    custom.programs.picosnitch = {
      enable = mkEnableOption "picosnitch network monitor";

      package = mkOption {
        type = types.package;
        default = pkgs.unstable.picosnitch;
        defaultText = literalExpression "pkgs.unstable.picosnitch";
        description = ''
          picosnitch package to use. 2.x is required, and the release channel
          still carries 1.0.3 — which keeps its configuration in the invoking
          user's home instead of `/etc/picosnitch`, and is marked insecure in
          nixpkgs.
        '';
      };

      settings = mkOption {
        inherit (tomlFormat) type;
        default = { };
        example = literalExpression ''
          {
            database.text_log = true;
            log.ignore_ports = [ 53 ];
          }
        '';
        description = ''
          Contents of `/etc/picosnitch/config.toml`. When no file exists the
          daemon writes one carrying every option at its default, so a running
          machine documents the full set for the version in use.

          Connections go to `${stateDir}/picosnitch.db` and are pruned after
          `database.retention_days`. `database.text_log` adds a CSV line per
          connection under `${logDir}`, and `database.remote` sends the same
          rows to a PostgreSQL or MySQL server — the only form of the record
          that outlives the machine which made it.
        '';
      };

      webUi = {
        enable = mkEnableOption "the picosnitch web dashboard";

        address = mkOption {
          type = types.str;
          default = "127.0.0.1";
          description = ''
            Address the dashboard binds to. It carries no authentication of its
            own, so anything other than a loopback address needs something in
            front of it.
          '';
        };

        port = mkOption {
          type = types.port;
          default = 5100;
          description = "Port the dashboard listens on.";
        };
      };
    };
  };

  config = mkIf cfg.enable {

    assertions = [
      {
        assertion = versionAtLeast cfg.package.version "2";
        message = ''
          custom.programs.picosnitch writes the `/etc/picosnitch/config.toml`
          of picosnitch 2.x, but ${cfg.package.version} is set as the package.
        '';
      }
    ];

    environment = {
      systemPackages = [ cfg.package ];

      # A copy rather than the usual store symlink: the daemon opens this path
      # `O_NOFOLLOW`, refuses anything that is not a regular file with a single
      # link, and then fchowns and fchmods it to root-owned 0600 itself.
      etc."picosnitch/config.toml" = {
        source = tomlFormat.generate "picosnitch-config.toml" settings;
        mode = "0600";
      };
    };

    users.groups.${group} = { };

    systemd.services = {
      picosnitch = {
        description = "picosnitch network monitor daemon";
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          ExecStart = "${getExe cfg.package} start-no-daemon";
          Restart = "always";
          RestartSec = "5s";

          # `ProtectSystem` leaves these writable: the directory settings imply
          # a bind mount each. The daemon insists on owning all five, including
          # the configuration directory, whose mode and ownership it resets on
          # every start.
          CacheDirectory = "picosnitch";
          ConfigurationDirectory = "picosnitch";
          LogsDirectory = "picosnitch";
          RuntimeDirectory = "picosnitch";
          StateDirectory = "picosnitch";

          # libbpf maps the per-CPU ring buffers, which is past the inherited
          # 8 MiB lock limit.
          LimitMEMLOCK = "infinity";

          # CAP_CHOWN hands the directories, files and event socket to
          # `data.group`; CAP_FOWNER re-chmods files a non-root `data.owner` holds.
          CapabilityBoundingSet = [
            "CAP_BPF"
            "CAP_CHOWN"
            "CAP_DAC_OVERRIDE"
            "CAP_DAC_READ_SEARCH"
            "CAP_FOWNER"
            "CAP_NET_ADMIN"
            "CAP_PERFMON"
            "CAP_SETGID"
            "CAP_SETUID"
            "CAP_SYS_ADMIN"
            "CAP_SYS_PTRACE"
          ];
          LockPersonality = true;
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectClock = true;
          ProtectControlGroups = true;
          # Executables are hashed wherever they live, $HOME included.
          ProtectHome = "read-only";
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectSystem = "strict";
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
        };
      };

      picosnitch-webui = mkIf cfg.webUi.enable {
        description = "picosnitch web dashboard";
        wantedBy = [ "multi-user.target" ];
        after = [ "picosnitch.service" ];

        environment = {
          PICOSNITCH_HOST = cfg.webUi.address;
          PICOSNITCH_PORT = toString cfg.webUi.port;
        };

        serviceConfig = {
          ExecStart = "${getExe cfg.package} webui";
          Restart = "on-failure";
          # It exits when the database is missing, which is every start before
          # the daemon has committed its first transaction.
          RestartSec = "10s";

          # Reads the database and subscribes to the event socket, and needs
          # nothing else: no capability, and the group is what the daemon hands
          # both of them to.
          DynamicUser = true;
          SupplementaryGroups = [ group ];

          # An empty list would render no directive at all; the empty string is
          # what clears the set.
          CapabilityBoundingSet = "";
          LockPersonality = true;
          NoNewPrivileges = true;
          PrivateDevices = true;
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectSystem = "strict";
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
          ];
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          SystemCallArchitectures = "native";
          UMask = "0077";
        };
      };
    };
  };
}
