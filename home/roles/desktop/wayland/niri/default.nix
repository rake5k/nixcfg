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
            workspaceIndicator = {
              name = "niri/workspaces";
            };
            windowIndicator = {
              name = "niri/window";
            };
            volumeCtl = { inherit (cfg.volumeCtl) spawnCmd; };
          };
        };
      };
    };

    # On non-NixOS, the user `systemd` instance is started by PAM with a minimal
    # `XDG_DATA_DIRS` that does not include `~/.nix-profile/share`, so the units
    # shipped by `pkgs.niri` are invisible to `systemctl --user`. Mirror them
    # into `~/.config/systemd/user/`, which is always in the search path, so
    # `niri-session` (which runs `systemctl --user start niri.service`) works.
    xdg.configFile = mkIf config.custom.base.non-nixos.enable {
      "systemd/user/niri.service".source = "${pkgs.niri}/share/systemd/user/niri.service";
      "systemd/user/niri-shutdown.target".source = "${pkgs.niri}/share/systemd/user/niri-shutdown.target";
    };

    programs = {
      niri = {
        enable = true;
        package = pkgs.niri;
        settings = {

          # Input
          input = {
            keyboard = {
              numlock = true;
              xkb = {
                layout = "de,de";
                options = "grp:rctrl_toggle,grp_led:scroll";
                variant = "bone,neo_qwertz";
              };
            };
          };

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
          };

          layer-rules = [
            {
              # Block out notifications from screencasts.
              matches = [ { namespace = "^notifications$"; } ];
              block-out-from = "screencast";
            }
          ];

          # Window rules
          window-rules = [
            {
              # Rounded corners
              geometry-corner-radius = {
                bottom-left = 3.;
                bottom-right = 3.;
                top-left = 3.;
                top-right = 3.;
              };
              clip-to-geometry = true;
            }
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
            {
              # Indicate screencasted windows with red colors.
              matches = [ { is-window-cast-target = true; } ];

              focus-ring = {
                active.color = "#f38ba8";
                inactive.color = "#7d0d2d";
              };

              border = {
                inactive.color = "#7d0d2d";
              };

              shadow = {
                color = "#7d0d2d70";
              };

              tab-indicator = {
                active.color = "#f38ba8";
                inactive.color = "#7d0d2d";
              };
            }
            {
              # Block out password managers from screencasts.
              matches = [
                { app-id = "^1password$"; }
                { app-id = "KeePassXC$"; }
              ];
              block-out-from = "screencast";
            }
            {
              # Block out messaging apps from screencasts.
              matches = [
                { title = "^Element"; }
                { title = "^Proton Mail"; }
                { title = "^Threema"; }
              ];
              block-out-from = "screencast";
            }
          ];

          # Keybinds
          binds = {
            # Hotkey overlay
            "Mod+Shift+K".action.show-hotkey-overlay = { };

            # Program launching
            "Mod+T" = {
              hotkey-overlay.title = "Open a Terminal";
              action.spawn = "${getExe pkgs.kitty}";
            };
            "Mod+D" = {
              hotkey-overlay.title = "Run an Application";
              action.spawn = "${getExe pkgs.fuzzel}";
            };
            "Mod+E" = {
              hotkey-overlay.title = "Select an emojo";
              action.spawn = "${getExe pkgs.rofimoji} --selector fuzzel";
            };

            "Super+Alt+L" = {
              hotkey-overlay.title = "Lock the Screen";
              action.spawn = "${cfg.lockerCfg.lockerCmd}";
            };

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

            # Overview
            "Mod+O" = {
              repeat = false;
              action.toggle-overview = { };
            };

            # Close window
            "Mod+Q" = {
              repeat = false;
              action.close-window = { };
            };

            # Window navigation
            "Mod+Left".action.focus-column-left = { };
            "Mod+Down".action.focus-window-down = { };
            "Mod+Up".action.focus-window-up = { };
            "Mod+Right".action.focus-column-right = { };
            "Mod+B".action.focus-column-left = { };
            "Mod+N".action.focus-window-down = { };
            "Mod+R".action.focus-window-up = { };
            "Mod+S".action.focus-column-right = { };

            "Mod+Ctrl+Left".action.move-column-left = { };
            "Mod+Ctrl+Down".action.move-window-down = { };
            "Mod+Ctrl+Up".action.move-window-up = { };
            "Mod+Ctrl+Right".action.move-column-right = { };
            "Mod+Ctrl+B".action.move-column-left = { };
            "Mod+Ctrl+N".action.move-window-down = { };
            "Mod+Ctrl+R".action.move-window-up = { };
            "Mod+Ctrl+S".action.move-column-right = { };

            # First/last column
            "Mod+Home".action.focus-column-first = { };
            "Mod+End".action.focus-column-last = { };
            "Mod+Ctrl+Home".action.move-column-to-first = { };
            "Mod+Ctrl+End".action.move-column-to-last = { };

            # Monitor navigation
            "Mod+Shift+Left".action.focus-monitor-left = { };
            "Mod+Shift+Down".action.focus-monitor-down = { };
            "Mod+Shift+Up".action.focus-monitor-up = { };
            "Mod+Shift+Right".action.focus-monitor-right = { };
            "Mod+Shift+B".action.focus-monitor-left = { };
            "Mod+Shift+N".action.focus-monitor-down = { };
            "Mod+Shift+R".action.focus-monitor-up = { };
            "Mod+Shift+S".action.focus-monitor-right = { };

            # Move to monitor
            "Mod+Shift+Ctrl+Left".action.move-column-to-monitor-left = { };
            "Mod+Shift+Ctrl+Down".action.move-column-to-monitor-down = { };
            "Mod+Shift+Ctrl+Up".action.move-column-to-monitor-up = { };
            "Mod+Shift+Ctrl+Right".action.move-column-to-monitor-right = { };
            "Mod+Shift+Ctrl+B".action.move-column-to-monitor-left = { };
            "Mod+Shift+Ctrl+N".action.move-column-to-monitor-down = { };
            "Mod+Shift+Ctrl+R".action.move-column-to-monitor-up = { };
            "Mod+Shift+Ctrl+S".action.move-column-to-monitor-right = { };

            # Workspace navigation
            "Mod+Page_Down".action.focus-workspace-down = { };
            "Mod+Page_Up".action.focus-workspace-up = { };
            "Mod+H".action.focus-workspace-down = { };
            "Mod+L".action.focus-workspace-up = { };

            # Move between workspaces
            "Mod+Ctrl+Page_Down".action.move-column-to-workspace-down = { };
            "Mod+Ctrl+Page_Up".action.move-column-to-workspace-up = { };
            "Mod+Ctrl+H".action.move-column-to-workspace-down = { };
            "Mod+Ctrl+L".action.move-column-to-workspace-up = { };

            # Workspace movement
            "Mod+Shift+Page_Down".action.move-workspace-down = { };
            "Mod+Shift+Page_Up".action.move-workspace-up = { };
            "Mod+Shift+H".action.move-workspace-down = { };
            "Mod+Shift+L".action.move-workspace-up = { };

            # Wheel navigation
            "Mod+WheelScrollDown" = {
              cooldown-ms = 150;
              action.focus-workspace-down = { };
            };
            "Mod+WheelScrollUp" = {
              cooldown-ms = 150;
              action.focus-workspace-up = { };
            };
            "Mod+Ctrl+WheelScrollDown" = {
              cooldown-ms = 150;
              action.move-column-to-workspace-down = { };
            };
            "Mod+Ctrl+WheelScrollUp" = {
              cooldown-ms = 150;
              action.move-column-to-workspace-up = { };
            };

            # Column direction
            "Mod+WheelScrollRight".action.focus-column-right = { };
            "Mod+WheelScrollLeft".action.focus-column-left = { };
            "Mod+Ctrl+WheelScrollRight".action.move-column-right = { };
            "Mod+Ctrl+WheelScrollLeft".action.move-column-left = { };

            # Alternative direction (Shift)
            "Mod+Shift+WheelScrollDown".action.focus-column-right = { };
            "Mod+Shift+WheelScrollUp".action.focus-column-left = { };
            "Mod+Ctrl+Shift+WheelScrollDown".action.move-column-right = { };
            "Mod+Ctrl+Shift+WheelScrollUp".action.move-column-left = { };

            # Workspace
            "Mod+1".action.focus-workspace = [ 1 ];
            "Mod+2".action.focus-workspace = [ 2 ];
            "Mod+3".action.focus-workspace = [ 3 ];
            "Mod+4".action.focus-workspace = [ 4 ];
            "Mod+5".action.focus-workspace = [ 5 ];
            "Mod+6".action.focus-workspace = [ 6 ];
            "Mod+7".action.focus-workspace = [ 7 ];
            "Mod+8".action.focus-workspace = [ 8 ];
            "Mod+9".action.focus-workspace = [ 9 ];

            # Move to workspace
            "Mod+Ctrl+1".action.move-column-to-workspace = [ 1 ];
            "Mod+Ctrl+2".action.move-column-to-workspace = [ 2 ];
            "Mod+Ctrl+3".action.move-column-to-workspace = [ 3 ];
            "Mod+Ctrl+4".action.move-column-to-workspace = [ 4 ];
            "Mod+Ctrl+5".action.move-column-to-workspace = [ 5 ];
            "Mod+Ctrl+6".action.move-column-to-workspace = [ 6 ];
            "Mod+Ctrl+7".action.move-column-to-workspace = [ 7 ];
            "Mod+Ctrl+8".action.move-column-to-workspace = [ 8 ];
            "Mod+Ctrl+9".action.move-column-to-workspace = [ 9 ];

            # Window consume/expel
            "Mod+BracketLeft".action.consume-or-expel-window-left = { };
            "Mod+BracketRight".action.consume-or-expel-window-right = { };

            "Mod+Comma".action.consume-window-into-column = { };
            "Mod+Period".action.expel-window-from-column = { };

            # Window height/width adjustment
            "Mod+A".action.switch-preset-column-width = { };
            "Mod+Shift+A".action.switch-preset-window-height = { };
            "Mod+Ctrl+A".action.reset-window-height = { };

            # Tiling
            "Mod+F".action.maximize-column = { };
            "Mod+Shift+F".action.fullscreen-window = { };

            # Column expansion
            "Mod+Ctrl+F".action.expand-column-to-available-width = { };

            # Center column
            "Mod+C".action.center-column = { };
            "Mod+Ctrl+C".action.center-visible-columns = { };

            # Window width adjustment
            "Mod+Minus".action.set-column-width = "-10%";
            "Mod+Equal".action.set-column-width = "+10%";

            # Window height adjustment
            "Mod+Shift+Minus".action.set-window-height = "-10%";
            "Mod+Shift+Equal".action.set-window-height = "+10%";

            # Floating windows
            "Mod+V".action.toggle-window-floating = { };
            "Mod+Shift+V".action.switch-focus-between-floating-and-tiling = { };

            # Tabbed display mode
            "Mod+W".action.toggle-column-tabbed-display = { };

            # Screenshot
            "Print".action.screenshot = { };
            "Ctrl+Print".action.screenshot-screen = { };
            "Alt+Print".action.screenshot-window = { };

            # Keyboard shortcuts inhibitor
            "Mod+Escape" = {
              allow-inhibiting = false;
              action.toggle-keyboard-shortcuts-inhibit = { };
            };

            # Quit
            "Mod+Shift+E".action.quit = { };
            "Ctrl+Alt+Delete".action.quit = { };

            # Screen mirroring
            "Mod+P" = {
              repeat = false;
              action.spawn-sh = "${getExe pkgs.wl-mirror} $(${getExe pkgs.niri} msg --json focused-output | jq -r .name)";
            };

            # Power off monitors
            "Mod+Shift+P".action.power-off-monitors = { };
          };
        };
      };
    };
  };
}
