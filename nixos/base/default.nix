{
  lib,
  config,
  pkgs,
  ...
}:

let

  cfg = config.custom.base;

  inherit (lib) mkOption types;

in

{
  options = {
    custom.base = {
      hostname = mkOption {
        type = types.str;
        description = "Host name.";
      };

      users = mkOption {
        type = with types; listOf str;
        default = [ ];
        description = "List of user names.";
      };
    };
  };

  config = {

    boot.tmp.cleanOnBoot = true;

    networking.hostName = cfg.hostname;

    programs = {
      git.enable = true;
      nano.enable = false;
      vim = {
        enable = true;
        defaultEditor = true;
      };
      zsh.enable = true;
    };

    security.sudo.package = pkgs.sudo.override { withInsults = true; };

    services.logind.settings.Login.HandlePowerKey = "ignore";
  };
}
