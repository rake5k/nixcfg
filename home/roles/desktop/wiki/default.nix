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
    home.packages = [ pkgs.logseq ];
  };
}
