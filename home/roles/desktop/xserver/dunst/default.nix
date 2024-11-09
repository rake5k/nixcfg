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
          default = pkgs.nerdfonts;
          description = "Font derivation";
        };

        family = mkOption {
          type = types.str;
          default = "VictorMono Nerd Font";
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
        size = "16x16";
      };
      settings = {
        global = {
          monitor = 0;
          follow = "none";
          width = "(0,1000)";
          height = "50";
          notification_limit = "6";
          origin = "top-right";
          offset = "15x40";
          indicate_hidden = "true";
          transparency = 5;
          separator_height = 2;
          padding = 6;
          horizontal_padding = 12;
          frame_width = 2;
          separator_color = "auto";
          sort = "true";
          idle_threshold = 2;
          font = "${cfg.font.family} 11";
          line_height = 3;
          format = "<b>[%a] %s %p</b>\\n%b";
          show_age_threshold = -1;
          ignore_newline = "false";
          stack_duplicates = "true";
          hide_duplicate_count = "false";
          show_indicators = "no";
          icon_position = "left";
          max_icon_size = 40;
          sticky_history = "true";
          history_length = 20;
          dmenu = "${pkgs.dmenu}/bin/dmenu";
          browser = "${pkgs.xdg-utils}/bin/xdg-open";

          # RULES
          word_wrap = "false";
          alignment = "left";
          markup = "full";
        };
        urgency_low = {
          frame_color = "#3B7C87";
          foreground = "#3B7C87";
          background = "#191311";
          timeout = "4s";
        };
        urgency_normal = {
          frame_color = "#5B8234";
          foreground = "#5B8234";
          background = "#191311";
          timeout = "6s";
        };
        urgency_critical = {
          frame_color = "#B7472A";
          foreground = "#B7472A";
          background = "#191311";
          timeout = "8s";
        };
      };
    };
  };
}
