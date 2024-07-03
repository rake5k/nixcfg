{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.base.non-nixos.home-manager.autoUpgrade;

in

{
  options = {
    custom.base.non-nixos.home-manager.autoUpgrade = {
      enable = mkEnableOption ''
        Whether to periodically upgrade the Home-Manager config to the latest
        version. If enabled, a systemd timer will run `home-manager switch`
        once a day.
      '';

      dates = mkOption {
        type = types.str;
        default = "04:40";
        example = "daily";
        description = ''
          How often or when upgrade occurs.

          The format is described in {manpage}`systemd.time(7)`.
        '';
      };

      flake = mkOption {
        type = types.str;
        default = "github:rake5k/nixcfg";
        description = "Flake URI of the Home-Manager configuration to build.";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.user = {
      # Needs to be started from the X session after importing the dbus session:
      #    systemctl --user import-environment DBUS_SESSION_DBUS_ADDRESS
      #    systemctl --user start dbus-environment.target
      targets.dbus-environment = {
        Unit = {
          Description = "Environment Imported Target";
        };
      };

      services.home-manager-upgrade = {
        Unit = {
          Description = "Home-Manager Upgrade";
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
        Service = {
          ExecStart = "${getExe pkgs.home-manager} switch -b hm-bak --impure --flake '${cfg.flake}'";
        };
      };


      timers.home-manager-upgrade = {
        Unit = {
          Requires = [ "dbus-environment.target" ];
          After = [ "dbus-environment.target" ];
        };
        Install = {
          WantedBy = [ "timers.target" ];
        };
        Timer = {
          OnCalendar = cfg.dates;
        };
      };
    };
  };
}
