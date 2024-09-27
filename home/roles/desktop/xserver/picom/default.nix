{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.desktop.xserver.picom;

in

{
  options = {
    custom.roles.desktop.xserver.picom = {
      enable = mkEnableOption "Picom compositor";
    };
  };

  config = mkIf cfg.enable {
    services.picom = {
      enable = true;
      package =
        if config.custom.base.non-nixos.enable
        then (config.lib.custom.nixGLWrap pkgs.picom)
        else pkgs.picom;
      backend = "glx";
      settings = {
        blur = {
          method = "gaussian";
          size = 10;
          deviation = 5.0;
        };
        blur-background-exclude = [
          "class_i = 'tray'"
          "name = 'as_toolbar'" # Zoom screen sharing toolbar
          "name = 'Nextcloud'"
          "window_type = 'utility'" # Firefox/Thunderbird dropdowns
        ];
        unredir-if-possible = false; # Stop IntelliJ from flickering
      };
      fade = true;
      fadeDelta = 5;
      fadeExclude = [
        "window_type *= 'menu'"
        "window_type = 'utility'"
      ];
      inactiveOpacity = 0.9;
      opacityRules = [
        "60:window_type = 'dock'"

        "100:_NET_WM_STATE@:32a ~= '_NET_WM_STATE_MAXIMIZED_*'"
        "100:_NET_WM_STATE@:32a *= '_NET_WM_STATE_FULLSCREEN'"
        "100:fullscreen"

        # App specifics
        "100:class_g = 'Alacritty' && focused"
        "100:class_g *= 'Microsoft Teams'"
        "100:class_g = 'trayer'"
        "100:name ^= 'Slack | Slack call'"
        "100:name *= 'Zoom Meeting'" # Zoom meeting window
        "100:name = 'as_toolbar'" # Zoom screen sharing toolbar
        "100:name *= 'i3lock'"
        "100:window_type = 'utility'" # Firefox/Thunderbird dropdowns
      ];
      shadow = true;
      shadowExclude = [
        "window_type *= 'menu'"

        # App specifics
        "class_g = 'trayer'"
        "name = 'as_toolbar'" # Zoom screen sharing toolbar
        "name = 'Nextcloud'"
        "name ~= 'cpt_frame(_xcb)?_window'" # Zoom screen sharing frame
        "window_type = 'utility'" # Firefox/Thunderbird dropdowns
      ];
      vSync = true;
    };
  };
}
