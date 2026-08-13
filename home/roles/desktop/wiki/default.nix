{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  desktopCfg = config.custom.roles.desktop;
  cfg = desktopCfg.wiki;

in

{
  options = {
    custom.roles.desktop.wiki = {
      enable = mkEnableOption "Wiki";

      package = mkOption {
        type = types.package;
        default = pkgs.logseq;
        description = "Wiki package";
      };

      spawnCmd = mkOption {
        type = types.str;
        default = "logseq";
        description = "Command to spawn the wiki";
      };
    };
  };

  config = mkIf cfg.enable {
    # The Logseq folder below is inert without it; hosts that must not run
    # Syncthing set `custom.roles.syncthing.enable = mkForce false`.
    custom.roles.syncthing.enable = mkDefault true;

    home.packages = [ pkgs.logseq ];

    services.syncthing = {
      settings = {
        folders = {
          Logseq = {
            enable = true;
            devices = [
              config.services.syncthing.settings.devices.hyperion.name
            ];
            id = "erdif-3jmbn";
            path = "~/Documents/notes/home";
          };
        };
      };
    };
  };
}
