{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.desktop.xserver.dunst;

in

{
  options = {
    custom.roles.desktop.xserver.dunst = {
      enable = mkEnableOption "Dunst desktop notification daemon";

      font = {
        package = mkOption {
          type = types.package;
          default = pkgs.nerdfonts.override { fonts = [ "Monofur" ]; };
          description = "Font derivation";
        };

        family = mkOption {
          type = types.str;
          default = "Monofur Nerd Font";
          description = "Font family";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      libnotify
      cfg.font.package
    ];

    services.dunst = {
      enable = true;
      iconTheme = {
        package = pkgs.paper-icon-theme;
        name = "Paper";
        size = "32x32";
      };
      settings = {
        global = {
          monitor = 0;
          follow = "none";
          notification_limit = "6";
          offset = "15x40";
          indicate_hidden = "true";
          sort = "true";
          idle_threshold = 2;
          line_height = 3;
          format = "<b>[%a] %s %p</b>\\n%b";
          show_age_threshold = -1;
          ignore_newline = "false";
          stack_duplicates = "true";
          hide_duplicate_count = "false";
          show_indicators = "no";
          icon_position = "left";
          sticky_history = "true";
          history_length = 20;
          dmenu = "${pkgs.dmenu}/bin/dmenu";
          browser = "${pkgs.xdg-utils}/bin/xdg-open";

          # RULES
          word_wrap = "false";
          alignment = "left";
          markup = "full";
        };
      };
    };
  };
}
