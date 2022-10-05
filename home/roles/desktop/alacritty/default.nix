{ config, lib, pkgs, ... }:

with lib;

let

  desktopCfg = config.custom.roles.desktop;
  cfg = desktopCfg.alacritty;

in

{
  options = {
    custom.roles.desktop.alacritty = {
      enable = mkEnableOption "Alacritty terminal emulator";
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        desktopCfg.font.package
      ];

      sessionVariables =
        let
          terminal = "alacritty";
        in
        {
          TERMINAL = terminal;
          TERMCMD = terminal;
        };
    };

    programs.alacritty = {
      enable = true;
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
        key_bindings = [
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
