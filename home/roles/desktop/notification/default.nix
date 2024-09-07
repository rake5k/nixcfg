{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.desktop.notification;

  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

in

{
  options = {
    custom.roles.desktop.notification = {
      enable = mkEnableOption "Desktop notification daemon";

      offset = mkOption {
        description = "Positioning offset from the display corner";
        type = types.str;
        example = "15x40";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      libnotify
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
          inherit (cfg) offset;

          monitor = 0;
          follow = "none";
          notification_limit = "6";
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
