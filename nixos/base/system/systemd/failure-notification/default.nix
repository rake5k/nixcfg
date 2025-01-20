{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.base.system.systemd.failure-notification;

  inherit (config.lib.custom) ntfyTokenSecret ntfyUrlSecret ntfyTopic;
  inherit (lib)
    fixedWidthNumber
    getExe
    mkEnableOption
    mkForce
    mkIf
    mkOption
    toUpper
    types
    ;

  unitName = "failure-notification";

  # Nix implementation from https://discourse.nixos.org/t/how-to-use-toplevel-overrides-for-systemd/12501/4
  systemdOverrides =
    let
      mkOverride =
        { unitType, priority }:
        pkgs.writeTextDir "/etc/systemd/system/${unitType}.d/${fixedWidthNumber 2 priority}-${unitName}.conf" ''
          [Unit]
          OnFailure=${unitName}@%N.service
        '';
    in
    builtins.map mkOverride cfg.enableForUnits;

  overrideUnitType = types.submodule {
    options = {
      unitType = mkOption {
        type = types.enum [
          "automount"
          "device"
          "mount"
          "service"
          "socket"
          "swap"
          "target"
          "timer"
        ];
      };

      priority = mkOption {
        type = types.ints.between 0 100;
        default = 50;
      };
    };
  };

  prettyHostname = "${toUpper config.custom.base.hostname}";

  # Cannot reuse mkNtfyCommand from the custom lib since we need to replace Systemd specifiers.
  # Also: limit message to less than 4096 bytes to prevent turning the message into an attachment:
  # https://docs.ntfy.sh/publish/#limitations
  mkNtfyCommand = secretsCfg: ''
    ${getExe pkgs.curl} \
      -H "Authorization:Bearer $(${pkgs.coreutils}/bin/cat ${secretsCfg.${ntfyTokenSecret}.path})" \
      -H "Markdown: yes" \
      -H "Tags: rotating_light" \
      -H "Title: ${prettyHostname} - Systemd unit \`''${1}\` failed" \
      -d $'Journal tail:\n```\n'"$(${pkgs.systemd}/bin/journalctl --unit ''${1} --lines 10 --no-pager --boot | ${pkgs.coreutils}/bin/head -c 4065)"$'\n```' \
      "$(${pkgs.coreutils}/bin/cat ${secretsCfg.${ntfyUrlSecret}.path})${ntfyTopic}"
  '';
  notifyFailure = mkNtfyCommand config.age.secrets;

in
{
  options = {
    custom.base.system.systemd.failure-notification = {
      enable = mkEnableOption "Systemd Failure Notification" // {
        description = ''
          Whenever a systemd unit fails, this service gets triggered and sends out a notification.
          This modules utilizes what's called "Systemd Top-Level Drop-In Override" to add `OnFailure`
          override to all units of the specified type(s) without modifying their Nix definition.
        '';
      };

      enableForUnits = mkOption {
        type = types.listOf overrideUnitType;
        default = [
          { unitType = "automount"; }
          { unitType = "device"; }
          { unitType = "mount"; }
          { unitType = "service"; }
          { unitType = "swap"; }
          { unitType = "target"; }
          { unitType = "timer"; }
        ];
      };
    };
  };

  config = mkIf cfg.enable {
    custom.base.agenix.secrets = [
      ntfyTokenSecret
      ntfyUrlSecret
    ];

    systemd = {
      packages = systemdOverrides;

      services."${unitName}@" = {
        description = "Systemd unit failure notification";
        onFailure = mkForce [ ];
        startLimitIntervalSec = 300;
        startLimitBurst = 1;
        scriptArgs = "%i";
        script = notifyFailure;
        serviceConfig = {
          Type = "oneshot";
        };
      };
    };
  };
}
