{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.programs.littlesnitch;

  inherit (lib)
    concatStringsSep
    getExe
    literalExpression
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    optionalString
    optionals
    types
    versionAtLeast
    ;

  tomlFormat = pkgs.formats.toml { };

  stateDir = "/var/lib/littlesnitch";
  overrideDir = "${stateDir}/override/config";

  # An override file replaces its factory counterpart rather than being merged
  # into it, and the daemon panics on a `web_ui.toml` missing a field that has
  # no serde default — `bind_address`, `bind_port` and `use_https`. The factory
  # file is of no help there: it is written after the overrides are parsed, so
  # it does not even exist on a first start. The file is therefore always
  # emitted in full, with `settings.web_ui` layered over the factory values.
  webUi =
    let
      base = {
        bind_address = "127.0.0.1";
        bind_port = 3031;
        use_https = false;
        # Every UI update travels over the web service itself, so leaving it
        # visible feeds an endless chain of updates into the connection list.
        hide_self_from_stats = true;
      }
      // (cfg.settings.web_ui or { });
    in
    base
    // {
      # The WebSocket upgrade is rejected unless its Origin is listed here.
      ui_base_urls =
        base.ui_base_urls or [
          "http${optionalString base.use_https "s"}://${base.bind_address}:${toString base.bind_port}"
        ];
    };

  # An empty `software_update.toml` switches the built-in update notification
  # off, which is what upstream asks redistributors to ship: updates come with
  # the system generation here. A definition of its own overrides that again.
  overrideFiles = cfg.settings // {
    software_update = cfg.settings.software_update or { };
    web_ui = webUi;
  };

  kernel = config.boot.kernelPackages.kernel;

in

{
  options = {
    custom.programs.littlesnitch = {
      enable = mkEnableOption "Little Snitch network monitor";

      package = mkOption {
        type = types.package;
        default = pkgs.callPackage ../../../pkgs/littlesnitch { };
        defaultText = literalExpression "pkgs.callPackage ../../../pkgs/littlesnitch { }";
        description = "Little Snitch package to use.";
      };

      startBeforeNetwork = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Hold back `network-pre.target` until the eBPF programs are attached,
          as the unit upstream ships does. Connections of processes started
          before the daemon cannot be attributed and show up as "Not
          Identified", so this is what makes the connection list complete.

          It costs what the daemon needs to get its programs past the
          verifier — measured at around 45 seconds since 1.1.0, which works
          around a change in Linux 7.1 — and every boot pays it before
          networking comes up. Turn it off where reaching the machine quickly
          matters more than attributing the first few connections.
        '';
      };

      settings = mkOption {
        type = types.attrsOf tomlFormat.type;
        default = { };
        example = literalExpression ''
          {
            main.deny_by_default = true;
            web_ui.bind_address = "192.168.83.10";
          }
        '';
        description = ''
          Configuration files placed in `${overrideDir}`, one per attribute,
          taking precedence over the factory defaults the daemon writes to
          `${stateDir}/config` on each start. Those factory files document
          every option and are the authoritative reference for the running
          version.

          A file written here replaces its factory counterpart whole, so
          anything left out falls back to the daemon's built-in default rather
          than to the factory value. `web_ui` is the exception: it is merged
          over the factory values and always written.
        '';
      };
    };
  };

  config = mkIf cfg.enable {

    assertions = [
      {
        assertion = versionAtLeast kernel.version "6.12";
        message = ''
          Little Snitch needs a kernel of at least 6.12 for its eBPF programs
          to pass the verifier, but ${kernel.version} is configured.
        '';
      }
    ];

    environment.systemPackages = [ cfg.package ];

    systemd.services.littlesnitch = {
      description = "Little Snitch network monitor daemon";
      wantedBy = [ "multi-user.target" ];

      after = [ "sysinit.target" ];
      before = optionals cfg.startBeforeNetwork [ "network-pre.target" ];
      wants = optionals cfg.startBeforeNetwork [ "network-pre.target" ];

      unitConfig.AssertCapability = [
        "CAP_BPF"
        "CAP_DAC_READ_SEARCH"
        "CAP_NET_BIND_SERVICE"
        "CAP_PERFMON"
        "CAP_SETPCAP"
        "CAP_SYS_ADMIN"
        "CAP_SYS_RESOURCE"
        "CAP_SETUID"
        "CAP_SETGID"
      ];

      # Rebuilt rather than updated so a removed attribute removes its file.
      preStart = ''
        rm -rf ${overrideDir}
        mkdir -p ${overrideDir}
        ${concatStringsSep "\n" (
          mapAttrsToList (
            name: value:
            "install -m0644 ${tomlFormat.generate "littlesnitch-${name}.toml" value} ${overrideDir}/${name}.toml"
          ) overrideFiles
        )}
      '';

      serviceConfig = {
        # The daemon signals readiness once its eBPF programs are attached,
        # which is what `startBeforeNetwork` waits on.
        Type = "notify";
        # CAP_SYS_ADMIN covers what CAP_NET_ADMIN does not on some
        # distributions; the daemon drops whatever it does not need.
        ExecStart = "${getExe cfg.package} --daemon --use-cap-sys-admin";
        Restart = "on-failure";
        RestartSec = "5s";
        StateDirectory = "littlesnitch";

        CapabilityBoundingSet = [
          "CAP_BPF"
          "CAP_DAC_READ_SEARCH"
          "CAP_NET_BIND_SERVICE"
          "CAP_PERFMON"
          "CAP_SETPCAP"
          "CAP_SYS_ADMIN"
          "CAP_SYS_RESOURCE"
          "CAP_SETUID"
          "CAP_SETGID"
        ];
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectProc = "noaccess";
        ProtectSystem = "full";
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
        ];

        # Logs are written to the journal by the daemon itself.
        StandardOutput = "null";
        StandardError = "journal";
      };
    };
  };
}
