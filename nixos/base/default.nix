{
  lib,
  config,
  pkgs,
  ...
}@args:

let

  cfg = config.custom.base;

  availableUsers = [
    "christian"
    "demo"
    "gamer"
  ];
  importUserModule =
    u:
    let
      isEnabled = builtins.any (x: x == u) cfg.users;
      userConfig = ./users + "/${u}.nix";
    in
    lib.mkIf isEnabled (import userConfig args);
  importUserModules = map importUserModule availableUsers;

in

{
  imports = importUserModules;

  options = with lib; {
    custom.base = {
      hostname = mkOption {
        type = types.str;
        description = "Host name.";
      };

      users = mkOption {
        type = types.listOf (types.enum availableUsers);
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

    services.logind.extraConfig = ''
      HandlePowerKey=ignore
    '';
  };
}
