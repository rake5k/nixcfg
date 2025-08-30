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

      commandArgPrefix = mkOption {
        type = types.str;
        default = "";
        description = "Command argument prefix to spawn a shell command inside the default terminal emulator";
      };

      titleArgPrefix = mkOption {
        type = types.str;
        default = "-T ";
        description = "Window title argument prefix";
      };
    };
  };

  config = mkIf cfg.enable {
    home = {
      sessionVariables = {
        TERMINAL = cfg.spawnCmd;
        TERMCMD = cfg.spawnCmd;
      };
    };

    programs.kitty = {
      enable = true;
      package = kitty;
      settings = {
        tab_bar_style = "powerline";
      };
    };
  };
}
