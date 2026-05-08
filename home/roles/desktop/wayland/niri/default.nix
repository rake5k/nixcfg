{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.desktop.wayland.niri;

  inherit (lib)
    getExe
    mkIf
    ;

  inherit (config.lib.custom) mkWindowManagerOptions;

in

{
  options = {
    custom.roles.desktop.wayland.niri = mkWindowManagerOptions "Niri";
  };

  config = mkIf cfg.enable {
    custom = {
      roles = {
        desktop = {
          notification = {
            enable = true;
            offset = "15x15";
          };
          wayland.waybar = {
            inherit (cfg) isMobile;
            enable = true;
            volumeCtl = {
              inherit (cfg.volumeCtl) spawnCmd;
            };
          };
        };
      };
    };

    programs = {
      niri = {
        enable = true;
        package = pkgs.niri;
        settings = {
          # Layout settings
          layout = {
            gaps = 12;

            border = {
              width = 2;
            };

            shadow = {
              enable = true;
              softness = 30;
              spread = 5;
              offset = {
                x = 0;
                y = 5;
              };
              color = "rgba(0, 0, 0, 7%)";
            };

            default-column-width = {
              proportion = 0.5;
            };
          };

          # Screenshot path
          screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

          # Hotkey overlay settings
          hotkey-overlay = {
            skip-at-startup = false;
          };

          # Animations
          animations = {
            enable = true;
            slowdown = null;
          };

          # Window rules
          window-rules = [
            {
              # Firefox picture-in-picture
              matches = [
                {
                  app-id = "firefox$";
                  title = ".*^Picture-in-Picture$";
                }
              ];
              open-floating = true;
            }
          ];

          # Keybinds
          binds = {
            # Constructive key strokes
            "Super+Shift+Return".action.spawn = "${getExe pkgs.kitty}";
            "Super+T".action.spawn = "${getExe pkgs.kitty}";

            # Launcher
            "Super+P".action.spawn = "${getExe pkgs.fuzzel}";
            "Super+E".action.spawn = "${getExe pkgs.rofimoji} --selector fuzzel";

            # Screenshots
            #"Super+Shift+T".action.spawn = "${cfg.screenshotCmdSelect}";
            #"Print".action.spawn = "${cfg.screenshotCmdFull}";
            #"Control+Print".action.spawn = "${cfg.screenshotCmdWindow}";
            #"Control+Shift+Print".action.spawn = "${cfg.screenshotCmdSelect}";

            # Locker
            #"Super+Shift+Delete".action.spawn = "${cfg.lockerCmd}";

            # Media keys
            "XF86AudioRaiseVolume".action.spawn = [
              "${pkgs.wireplumber}/bin/wpctl"
              "set-volume"
              "@DEFAULT_AUDIO_SINK@"
              "0.1+"
              "-l"
              "1.0"
            ];
            "XF86AudioLowerVolume".action.spawn = [
              "${pkgs.wireplumber}/bin/wpctl"
              "set-volume"
              "@DEFAULT_AUDIO_SINK@"
              "0.1-"
            ];
            "XF86AudioMute".action.spawn = [
              "${pkgs.wireplumber}/bin/wpctl"
              "set-mute"
              "@DEFAULT_AUDIO_SINK@"
              "toggle"
            ];
            "XF86AudioMicMute".action.spawn = [
              "${pkgs.wireplumber}/bin/wpctl"
              "set-mute"
              "@DEFAULT_AUDIO_SOURCE@"
              "toggle"
            ];

            # Media controls
            "XF86AudioMedia".action.spawn = "${getExe pkgs.playerctl} play-pause";
            "XF86AudioPlay".action.spawn = "${getExe pkgs.playerctl} play-pause";
            "XF86AudioPrev".action.spawn = "${getExe pkgs.playerctl} previous";
            "XF86AudioNext".action.spawn = "${getExe pkgs.playerctl} next";
            "XF86AudioStop".action.spawn = "${getExe pkgs.playerctl} stop";

            # Brightness
            "XF86MonBrightnessDown".action.spawn = "${getExe pkgs.brightnessctl} set 10%-";
            "XF86MonBrightnessUp".action.spawn = "${getExe pkgs.brightnessctl} set 10%+";

            # Bluetooth
            "XF86Bluetooth".action.spawn = ''
              ${pkgs.bash}/bin/bash -c "if rfkill list bluetooth | grep -q 'yes$'; then rfkill unblock bluetooth; else rfkill block bluetooth; fi"
            '';

            # Eject
            "XF86Eject".action.spawn = "eject -T";

            # Calculator
            "XF86Calculator".action.spawn = "${getExe pkgs.eva}";

            # File manager
            "XF86Explorer".action.spawn = "${getExe pkgs.yazi}";

            # Browser
            "XF86HomePage".action.spawn = "xdg-open";

            # Hotkey overlay
            "Super+Shift+Slash".action.show-hotkey-overlay = { };

            # Overview
            "Super+O" = {
              repeat = false;
              action.toggle-overview = { };
            };

            # Close window
            "Super+Q" = {
              repeat = false;
              action.close-window = { };
            };

            # Window navigation (arrow keys)
            "Super+Left".action.focus-column-left = { };
            "Super+Down".action.focus-window-down = { };
            "Super+Up".action.focus-window-up = { };
            "Super+Right".action.focus-column-right = { };

            # Workspace navigation
            "Super+Page_Down".action.focus-workspace-down = { };
            "Super+Page_Up".action.focus-workspace-up = { };
            "Super+U".action.focus-workspace-down = { };
            "Super+I".action.focus-workspace-up = { };

            # Move between workspaces
            "Super+Ctrl+Page_Down".action.move-column-to-workspace-down = { };
            "Super+Ctrl+Page_Up".action.move-column-to-workspace-up = { };
            "Super+Ctrl+U".action.move-column-to-workspace-down = { };
            "Super+Ctrl+I".action.move-column-to-workspace-up = { };

            # Screenshot
            "Print".action.screenshot = { };
            "Ctrl+Print".action.screenshot-screen = { };
            "Alt+Print".action.screenshot-window = { };

            # Keyboard shortcuts inhibitor
            "Super+Escape" = {
              allow-inhibiting = false;
              action.toggle-keyboard-shortcuts-inhibit = { };
            };

            # Quit
            "Super+Shift+E".action.quit = { };
            "Ctrl+Alt+Delete".action.quit = { };

            # Power off monitors
            "Super+Shift+P".action.power-off-monitors = { };

            # Monitor navigation
            "Super+Shift+Left".action.focus-monitor-left = { };
            "Super+Shift+Down".action.focus-monitor-down = { };
            "Super+Shift+Up".action.focus-monitor-up = { };
            "Super+Shift+Right".action.focus-monitor-right = { };

            # Move to monitor
            "Super+Shift+Ctrl+Left".action.move-column-to-monitor-left = { };
            "Super+Shift+Ctrl+Down".action.move-column-to-monitor-down = { };
            "Super+Shift+Ctrl+Up".action.move-column-to-monitor-up = { };
            "Super+Shift+Ctrl+Right".action.move-column-to-monitor-right = { };

            # First/last column
            "Super+Home".action.focus-column-first = { };
            "Super+End".action.focus-column-last = { };
            "Super+Ctrl+Home".action.move-column-to-first = { };
            "Super+Ctrl+End".action.move-column-to-last = { };

            # Wheel navigation
            "Super+WheelScrollDown" = {
              cooldown-ms = 150;
              action.focus-workspace-down = { };
            };
            "Super+WheelScrollUp" = {
              cooldown-ms = 150;
              action.focus-workspace-up = { };
            };
            "Super+Ctrl+WheelScrollDown" = {
              cooldown-ms = 150;
              action.move-column-to-workspace-down = { };
            };
            "Super+Ctrl+WheelScrollUp" = {
              cooldown-ms = 150;
              action.move-column-to-workspace-up = { };
            };

            # Column direction
            "Super+WheelScrollRight".action.focus-column-right = { };
            "Super+WheelScrollLeft".action.focus-column-left = { };
            "Super+Ctrl+WheelScrollRight".action.move-column-right = { };
            "Super+Ctrl+WheelScrollLeft".action.move-column-left = { };

            # Alternative direction (Shift)
            "Super+Shift+WheelScrollDown".action.focus-column-right = { };
            "Super+Shift+WheelScrollUp".action.focus-column-left = { };
            "Super+Ctrl+Shift+WheelScrollDown".action.move-column-right = { };
            "Super+Ctrl+Shift+WheelScrollUp".action.move-column-left = { };

            # Workspace
            "Super+1".action.focus-workspace = [ 1 ];
            "Super+2".action.focus-workspace = [ 2 ];
            "Super+3".action.focus-workspace = [ 3 ];
            "Super+4".action.focus-workspace = [ 4 ];
            "Super+5".action.focus-workspace = [ 5 ];
            "Super+6".action.focus-workspace = [ 6 ];
            "Super+7".action.focus-workspace = [ 7 ];
            "Super+8".action.focus-workspace = [ 8 ];
            "Super+9".action.focus-workspace = [ 9 ];

            # Move to workspace
            "Super+Ctrl+1".action.move-column-to-workspace = [ 1 ];
            "Super+Ctrl+2".action.move-column-to-workspace = [ 2 ];
            "Super+Ctrl+3".action.move-column-to-workspace = [ 3 ];
            "Super+Ctrl+4".action.move-column-to-workspace = [ 4 ];
            "Super+Ctrl+5".action.move-column-to-workspace = [ 5 ];
            "Super+Ctrl+6".action.move-column-to-workspace = [ 6 ];
            "Super+Ctrl+7".action.move-column-to-workspace = [ 7 ];
            "Super+Ctrl+8".action.move-column-to-workspace = [ 8 ];
            "Super+Ctrl+9".action.move-column-to-workspace = [ 9 ];

            # Tiling
            "Super+F".action.maximize-column = { };
            "Super+Shift+F".action.fullscreen-window = { };

            # Window height/width adjustment
            "Super+R".action.switch-preset-column-width = { };
            "Super+Shift+R".action.switch-preset-window-height = { };
            "Super+Ctrl+R".action.reset-window-height = { };

            # Center column
            "Super+C".action.center-column = { };
            "Super+Ctrl+C".action.center-visible-columns = { };

            # Window width adjustment
            "Super+Minus".action.set-column-width = "-10%";
            "Super+Equal".action.set-column-width = "+10%";

            # Window height adjustment
            "Super+Shift+Minus".action.set-window-height = "-10%";
            "Super+Shift+Equal".action.set-window-height = "+10%";

            # Floating windows
            "Super+V".action.toggle-window-floating = { };
            "Super+Shift+V".action.switch-focus-between-floating-and-tiling = { };

            # Tabbed display mode
            "Super+W".action.toggle-column-tabbed-display = { };

            # Column expansion
            "Super+Ctrl+F".action.expand-column-to-available-width = { };

            # Window consume/expel
            "Super+BracketLeft".action.consume-or-expel-window-left = { };
            "Super+BracketRight".action.consume-or-expel-window-right = { };

            "Super+Comma".action.consume-window-into-column = { };
            "Super+Period".action.expel-window-from-column = { };

            # Workspace movement
            "Super+Shift+Page_Down".action.move-workspace-down = { };
            "Super+Shift+Page_Up".action.move-workspace-up = { };
            "Super+Shift+U".action.move-workspace-down = { };
            "Super+Shift+I".action.move-workspace-up = { };
          };
        };
      };

      # supporting tools
      fuzzel = {
        enable = true;
        settings = {
          main = {
            terminal = "${getExe pkgs.kitty}";
            layer = "overlay";
          };
        };
      };

      swaylock = {
        enable = true;
        settings = {
          show-failed-attempts = true;
          show-keyboard-layout = true;
        };
      };
    };
  };
}
