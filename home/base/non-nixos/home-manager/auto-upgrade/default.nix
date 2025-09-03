{
  config,
  lib,
  pkgs,
  ...
}:

let

  hmCfg = config.custom.base.non-nixos.home-manager;
  cfg = hmCfg.autoUpgrade;

  inherit (lib)
    getExe
    mkEnableOption
    mkIf
    mkOption
    types
    ;

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
        default = hmCfg.flake;
        description = "Flake URI of the Home-Manager configuration to build.";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.user = {
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
