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

      font = {
        package = mkOption {
          type = types.package;
          default = pkgs.nerd-fonts.zed-mono;
          description = "Font derivation";
        };

        family = mkOption {
          type = types.str;
          default = "ZedMono Nerd Font Mono";
          description = "Font family";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = [ cfg.font.package ];

      sessionVariables = {
        TERMINAL = cfg.spawnCmd;
        TERMCMD = cfg.spawnCmd;
      };
    };

    programs.kitty = {
      enable = true;
      package = kitty;
      font = {
        inherit (cfg.font) package;
        name = cfg.font.family;
        size = 13;
      };
      settings = {
        background_opacity = 0.8;
        background_blur = 64;
        tab_bar_style = "powerline";
      };
    };
  };
}
