{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.desktop.terminal;

  kitty = config.lib.nixGL.wrap pkgs.kitty;

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
    custom.roles.desktop.terminal = {
      enable = mkEnableOption "Terminal emulator";

      package = mkOption {
        type = types.package;
        default = kitty;
        description = "Terminal emulator package";
      };

      spawnCmd = mkOption {
        type = types.str;
        default = "${getExe cfg.package}";
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
        cursor_trail = 1;
        cursor_trail_decay = "0.1 0.2";
        enable_audio_bell = false;
        open_url_with = "default";
        scrollback_fill_enlarged_window = true;
        scrollback_lines = 10000;
        show_hyperlink_targets = true;
        strip_trailing_spaces = "always";
        tab_bar_style = "powerline";
        update_check_interval = 0;
      };

      extraConfig = ''
        mouse_map ctrl+left click ungrabbed mouse_handle_click selection link prompt
        mouse_map left click ungrabbed no-op
      '';
    };
  };
}
