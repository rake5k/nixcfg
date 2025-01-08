{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  desktopCfg = config.custom.roles.desktop;
  cfg = desktopCfg.terminal;

  kitty = config.lib.nixGL.wrap pkgs.kitty;

in

{
  options = {
    custom.roles.desktop.terminal = {
      enable = mkEnableOption "Terminal emulator";

      package = mkOption {
        type = types.package;
        default = kitty;
        description = "Terminal emulator package";
      };

      spawnCmd = mkOption {
        type = types.str;
        default = "kitty";
        description = "Command to spawn the default terminal emulator";
      };

      commandSpawnCmd = mkOption {
        type = types.str;
        default = "kitty --command";
        description = "Command to spawn a shell command inside the default terminal emulator";
      };
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = [ desktopCfg.font.package ];

      sessionVariables = {
        TERMINAL = cfg.spawnCmd;
        TERMCMD = cfg.spawnCmd;
      };
    };

    programs.kitty = {
      enable = true;
      package = kitty;
      font = {
        inherit (desktopCfg.font) package;
        name = desktopCfg.font.familyMono;
        size = 15;
      };
    };
  };
}
