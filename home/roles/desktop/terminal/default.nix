{ config, lib, pkgs, ... }:

with lib;

let

  desktopCfg = config.custom.roles.desktop;
  cfg = desktopCfg.terminal;

  alacritty =
    if config.custom.base.non-nixos.enable && config.custom.roles.desktop.xserver.enable
    then (hiPrio (config.lib.custom.nixGLWrap pkgs.alacritty))
    else pkgs.alacritty;

in

{
  options = {
    custom.roles.desktop.terminal = {
      enable = mkEnableOption "Terminal emulator";

      package = mkOption {
        type = types.package;
        default = alacritty;
        description = "Terminal emulator package";
      };

      spawnCmd = mkOption {
        type = types.str;
        default = "alacritty";
        description = "Command to spawn the default terminal emulator";
      };

      commandSpawnCmd = mkOption {
        type = types.str;
        default = "alacritty --command";
        description = "Command to spawn a shell command inside the default terminal emulator";
      };
    };
  };

  config = mkIf cfg.enable
    {
      home = {
        packages = with pkgs; [
          desktopCfg.font.package
        ];

        sessionVariables = {
          TERMINAL = cfg.spawnCmd;
          TERMCMD = cfg.spawnCmd;
        };
      };

      programs.alacritty = {
        enable = true;
        package = alacritty;
        settings = {
          env.TERM = "xterm-256color";
          window = {
            dynamic_padding = true;
            opacity = 0.95;
          };
          font =
            let
              fontFamily = "${desktopCfg.font.family}";
            in
            {
              normal = {
                family = fontFamily;
                style = "SemiBold";
              };
              bold = {
                family = fontFamily;
                style = "Bold";
              };
              italic = {
                family = fontFamily;
                style = "Italic";
              };
              bold_italic = {
                family = fontFamily;
                style = "Bold Italic";
              };
              size = 11.5;
            };
          keyboard.bindings = [
            {
              key = "Key0";
              mods = "Control";
              action = "ResetFontSize";
            }
            {
              key = "Numpad0";
              mods = "Control";
              action = "ResetFontSize";
            }
            {
              key = "NumpadAdd";
              mods = "Control";
              action = "IncreaseFontSize";
            }
            {
              key = "Plus";
              mods = "Control|Shift";
              action = "IncreaseFontSize";
            }
            {
              key = "NumpadSubtract";
              mods = "Control";
              action = "DecreaseFontSize";
            }
          ];
        };
      };
    };
}
