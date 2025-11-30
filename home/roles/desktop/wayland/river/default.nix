{
  config,
  lib,
  pkgs,
  ...
}:

let

  desktopCfg = config.custom.roles.desktop;
  terminalCfg = desktopCfg.terminal;
  cfg = desktopCfg.wayland.river;

  inherit (config.lib) nixGL;

  # Wrap river to set PATH before starting, so all spawned processes inherit it
  riverWithPath = pkgs.symlinkJoin {
    name = "river-with-path";
    paths = [ (nixGL.wrap pkgs.river) ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/river \
        --prefix PATH : "${PATH}"
    '';
  };

  package = riverWithPath;
  launcherPackage = nixGL.wrap pkgs.fuzzel;
  terminalCmd = getExe terminalCfg.package;
  audioMuteToggle = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";

  PATH = "${config.home.homeDirectory}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:${config.home.homeDirectory}/bin:$PATH";

  waybarModulesPath = config.xdg.configFile."waybar/modules".target;

  inherit (lib) getExe mkIf;
  inherit (config.lib.custom) mkWindowManagerOptions;

  mkTag = tag: "$((1 << (${tag} - 1)))";

in

{
  options = {
    custom.roles.desktop.wayland.river = mkWindowManagerOptions "River";
  };

  config = mkIf cfg.enable {
    # Install river utilities (riverctl, rivertile) in PATH
    home.packages = [ riverWithPath ];

    custom = {
      roles = {
        desktop = {
          notification = {
            enable = true;
            offset = "15x15";
          };
        };
      };
    };

    programs = {
      fuzzel = {
        enable = true;
        package = launcherPackage;
        settings = {
          main = {
            terminal = terminalCmd;
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
      waybar = {
        enable = true;
        settings = {
          mainBar = {
            layer = "top";
            modules-left = [
              "custom/powermenu"
              "river/tags"
              "temperature"
            ];
            modules-center = [ "river/window" ];
            modules-right = [
              "battery"
              "backlight"
              "wireplumber"
              "custom/mic"
              "custom/cpu"
              "custom/clock"
              "tray"
            ];

            # Modules

            "custom/powermenu" = {
              format = "⏻";
              interval = "once";
              on-click = "${waybarModulesPath}/powermenu.sh";
              tooltip = false;
              signal = 8;
            };

            "river/tags" = {
              tag-labels = [
                "1"
                "2"
                "3"
                "4"
                "5"
                "6"
                "7"
              ];
              disable-click = false;
              num-tags = 7;
            };

            temperature = {
              hwmon-path = "/sys/class/hwmon/hwmon1/temp1_input";
              input-filename = "temp1_input";
              format = " {temperatureC}°C";
            };

            "river/window" = {
              format = "  {}";
              max-length = 90;
            };

            battery = {
              states = {
                good = 100;
                warning = 30;
                critical = 20;
              };
              format = "{icon}  {capacity}%";
              format-charging = "{icon}   {capacity}%";
              format-plugged = "{icon}   {capacity}%";
              format-icons = [
                ""
                ""
                ""
                ""
                ""
              ];
            };

            backlight = {
              device = "amdgpu_b10";
              format = "{icon}  {}%";
              format-icons = [
                ""
                ""
              ];
              interval = 1;
              scroll-step = 5.0;
            };

            wireplumber = {
              tooltip = false;
              scroll-step = 5.0;
              format = "{icon}  {volume}%";
              format-muted = "󰝟  0%";
              on-click = cfg.volumeCtl.spawnCmd;
              on-click-right = audioMuteToggle;
              format-icons = {
                default = [
                  ""
                  "󰖀"
                  "󰕾"
                ];
              };
            };

            "custom/cpu" = {
              interval = 1;
              return-type = "string";
              exec = "${waybarModulesPath}/cpu.sh";
              tooltip = false;
              on-click = "gnome-system-monitor";
            };

            "custom/clock" = {
              interval = 1;
              return-type = "string";
              exec = "${waybarModulesPath}/datetime.sh";
              tooltip = false;
              on-click = "gnome-clocks";
              on-click-right = "gnome-calendar";
            };

            tray = {
              icon-size = 18;
              show-passive-items = true;
              spacing = 10;
              reverse-direction = true;
            };
          };
        };

        style = # css
          ''
            #waybar {
              background: none;
            }

            #waybar.hidden {
              opacity: 0.2;
            }

            .module {
              margin: 6px 6px 0 6px;
              padding: 0 15px;
              border-radius: 5px;
              transition: none;
              background: @base00;
            }

            .module button {
              transition: none;
              color: @base03;
              background: transparent;
              border-radius: 0px;
            }

            .module button.occupied {
              transition: none;
              color: @base0B;
              background: transparent;
            }

            .module button.focused {
              color: @base0D;
              border-bottom: 3px solid @base0D;
              background: @base03;
              border-radius: inherit;
            }

            .module button:hover {
              transition: none;
              box-shadow: inherit;
              text-shadow: inherit;
              color: @base0D;
            }

            .module .critical {
              background-color: @base05;
              color: @base00;
            }

            #custom-powermenu {
              color: @base05;
              padding-right: 20px;
            }

            #tags {
              padding: 0;
            }

            #temperature {
              color: @base0D;
            }

            #battery {
              color: @base0B;
            }

            #battery.critical:not(.charging) {
              background-color: @base05;
              color: @base00;
              animation-name: blink;
              animation-duration: 0.5s;
              animation-timing-function: linear;
              animation-iteration-count: infinite;
              animation-direction: alternate;
            }

            @keyframes blink {
              to {
                background-color: @base08;
                color: @base05;
              }
            }

            #backlight {
              color: @base0A;
            }

            #wireplumber {
              color: @base09;
            }

            #custom-cpu {
              color: @base0E;
            }

            #custom-clock {
              color: @base08;
            }

            #tray {
              color: @base05;
            }
          '';
      };
    };

    stylix.targets = {
      waybar = {
        addCss = false;
        font = "sansSerif";
      };
    };

    wayland.windowManager.river = {
      inherit package;

      enable = true;

      extraSessionVariables = {
        inherit PATH;
        XDG_CURRENT_DESKTOP = "river";
      };

      /*
        # Super+Alt+Control+{H,J,K,L} to snap views to screen edges
        riverctl map normal Super+Alt+Control H snap left
        riverctl map normal Super+Alt+Control J snap down
        riverctl map normal Super+Alt+Control K snap up
        riverctl map normal Super+Alt+Control L snap right

        # Super+Alt+Shift+{H,J,K,L} to resize views
        riverctl map normal Super+Alt+Shift H resize horizontal -100
        riverctl map normal Super+Alt+Shift J resize vertical 100
        riverctl map normal Super+Alt+Shift K resize vertical -100
        riverctl map normal Super+Alt+Shift L resize horizontal 100

        # Super+{Up,Right,Down,Left} to change layout orientation
        riverctl map normal Super Up send-layout-cmd rivertile "main-location top"
        riverctl map normal Super Right send-layout-cmd rivertile "main-location right"
        riverctl map normal Super Down send-layout-cmd rivertile "main-location bottom"
        riverctl map normal Super Left send-layout-cmd rivertile "main-location left"

        # Set keyboard repeat rate
        riverctl set-repeat 50 300

        # Make all views with an app-id that starts with "float" and title "foo" start floating.
        riverctl rule-add -app-id 'float*' -title 'foo' float
      */

      settings = {
        declare-mode = [
          "locked"
          "normal"
          "passthrough"
        ];

        input = {
          "pointer-11311-45-SNSL002D:00_2C2F:002D_Touchpad" = {
            disable-while-typing = true;
            events = true;
            natural-scroll = true;
            pointer-accel = 0.4;
            tap = true;
          };
          "pointer-2-10-TPPS/2_Elan_TrackPoint" = {
            accel-profile = "flat";
            events = true;
            pointer-accel = 0.6;
          };
        };

        keyboard-layout = "-variant neo_qwertz,bone -options grp:rctrl_toggle,grp_led:scroll de,de";

        map = {
          normal = {
            # Constructive key strokes
            "Super+Shift Return" = "spawn ${terminalCmd}";
            "Super P" = "spawn '${getExe launcherPackage} --cache=${config.xdg.cacheHome}/fuzzel/launcher'";
            "Super E" = "spawn '${getExe pkgs.rofimoji} --selector fuzzel'";

            # Screenshots
            "Super S" = "spawn '${getExe pkgs.bash} ${cfg.screenshotCfg.screenshotCmdFull}'";
            "Super+Shift S" = "spawn '${getExe pkgs.bash} ${cfg.screenshotCfg.screenshotCmdSelect}'";
            "Print" = "spawn '${getExe pkgs.bash} ${cfg.screenshotCfg.screenshotCmdFull}'";
            "Control Print" = "spawn '${getExe pkgs.bash} ${cfg.screenshotCfg.screenshotCmdWindow}'";
            "Control+Shift Print" = "spawn '${getExe pkgs.bash} ${cfg.screenshotCfg.screenshotCmdSelect}'";

            # Destructive key strokes
            "Super+Shift C" = "close";
            "Super+Shift Delete" = "spawn '${cfg.lockerCfg.lockerCmd}'";
            "Super+Shift Q" = "exit";
            "Super Q" = "spawn ${config.xdg.configHome}/river/init";

            # Window navigation
            "Super J" = "focus-view next";
            "Super K" = "focus-view previous";
            "Super+Shift J" = "swap next";
            "Super+Shift K" = "swap previous";
            "Super Period" = "focus-output next";
            "Super Comma" = "focus-output previous";

            "Super+Shift Period" =
              "spawn '${getExe pkgs.bash} -c \"riverctl send-to-output -current-tags next && riverctl focus-output next\"'";
            "Super+Shift Comma" =
              "spawn '${getExe pkgs.bash} -c \"riverctl send-to-output -current-tags previous && riverctl focus-output previous\"'";

            # Super+Return to bump the focused view to the top of the layout stack
            "Super Return" = "zoom";

            # Super+H and Super+L to decrease/increase the main ratio of rivertile(1)
            "Super H" = "send-layout-cmd rivertile 'main-ratio -0.05'";
            "Super L" = "send-layout-cmd rivertile 'main-ratio +0.05'";

            # Super+Shift+H and Super+Shift+L to increment/decrement the main count of rivertile(1)
            "Super+Shift H" = "send-layout-cmd rivertile 'main-count +1'";
            "Super+Shift L" = "send-layout-cmd rivertile 'main-count -1'";

            "Super+Alt+Shift H" = "resize horizontal -100";
            "Super+Alt+Shift J" = "resize vertical 100";
            "Super+Alt+Shift K" = "resize vertical -100";
            "Super+Alt+Shift L" = "resize horizontal 100";

            "Super Space" = "toggle-float";
            "Super F" = "toggle-fullscreen";

            "Super F11" = "enter-mode passthrough";
          };

          passthrough = {
            "Super F11" = "enter-mode normal";
          };
        };

        map-pointer = {
          normal = {
            "Super BTN_LEFT" = "move-view";
            "Super BTN_RIGHT" = "resize-view";
            "Super BTN_MIDDLE" = "toggle-float";
          };
        };

        rule-add = {
          "-app-id" = {
            # Fix app borders
            "*" = "ssd";

            # App-specific rules
            "firefox".tags = mkTag "3";
            "firefox_firefox".tags = mkTag "3";
            "chromium".tags = mkTag "3";
            "chromium-browser".tags = mkTag "3";
            "jetbrains-idea".tags = mkTag "2";
            "org.keepassxc.KeePassXC".tags = mkTag "7";
            "kitty".tags = mkTag "1";
            "Logseq".tags = mkTag "6";
            "org.gnome.Evolution".tags = mkTag "5";
          };
          "-title" = {
            "'Microsoft Teams*'".tags = mkTag "4";
          };
        };

        set-cursor-warp = "on-output-change";

        spawn = map (x: x.command) cfg.autoruns;
      };

      extraConfig = ''
        ${getExe pkgs.swaybg} -i $(find ${cfg.wallpapersDir} -type f | ${pkgs.coreutils}/bin/shuf -n1) -m fill &

        riverctl default-layout rivertile
        rivertile -view-padding 6 -outer-padding 6 &

        riverctl focus-follows-cursor always

        # Various media key mapping examples for both normal and locked mode which do
        # not have a modifier
        for mode in normal locked
        do
            # Control pulse audio volume with pamixer (https://github.com/cdemoulins/pamixer)
            riverctl map $mode None XF86AudioRaiseVolume  spawn '${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+'
            riverctl map $mode None XF86AudioLowerVolume  spawn '${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-'
            riverctl map $mode None XF86AudioMicMute      spawn '${pkgs.wireplumber}/bin/wpctl set-source-mute @DEFAULT_SOURCE@ toggle'
            riverctl map $mode None XF86AudioMute         spawn '${audioMuteToggle}'

            # Control MPRIS aware media players with playerctl (https://github.com/altdesktop/playerctl)
            riverctl map $mode None XF86AudioMedia spawn '${getExe pkgs.playerctl} play-pause'
            riverctl map $mode None XF86AudioPlay  spawn '${getExe pkgs.playerctl} play-pause'
            riverctl map $mode None XF86AudioPrev  spawn '${getExe pkgs.playerctl} previous'
            riverctl map $mode None XF86AudioNext  spawn '${getExe pkgs.playerctl} next'
            riverctl map $mode None XF86AudioStop  spawn '${getExe pkgs.playerctl} stop'

            # Control screen backlight brightness with brightnessctl (https://github.com/Hummer12007/brightnessctl)
            riverctl map $mode None XF86MonBrightnessDown spawn '${getExe pkgs.brightnessctl} set 10%-'
            riverctl map $mode None XF86MonBrightnessUp   spawn '${getExe pkgs.brightnessctl} set 10%+'

            # Toggle wireless / bluethooth adapter
            riverctl map $mode None XF86Bluetooth  spawn '${getExe pkgs.bash} -c \"if rfkill list bluetooth|grep -q 'yes$';then rfkill unblock bluetooth;else rfkill block bluetooth;fi\"';
            
            # Eject the optical drive (well if you still have one that is)
            riverctl map $mode None XF86Eject spawn 'eject -T'

            # Quick access
            riverctl map $mode None XF86Calculator spawn '${terminalCmd} ${terminalCfg.commandArgPrefix}${getExe pkgs.eva}';
            riverctl map $mode None XF86Explorer   spawn '${terminalCmd} ${terminalCfg.commandArgPrefix}${getExe pkgs.yazi}';
            riverctl map $mode None XF86HomePage   spawn 'xdg-open';
        done

        # Set up tags (aka. "workspaces")
        for i in $(seq 1 9)
        do
            tags=$((1 << ($i - 1)))

            # Super+[1-9] to focus tag [0-8]
            riverctl map normal Super $i set-focused-tags $tags

            # Super+Shift+[1-9] to tag focused view with tag [0-8]
            riverctl map normal Super+Shift $i set-view-tags $tags

            # Super+Control+[1-9] to toggle focus of tag [0-8]
            riverctl map normal Super+Control $i toggle-focused-tags $tags

            # Super+Shift+Control+[1-9] to toggle tag [0-8] of focused view
            riverctl map normal Super+Shift+Control $i toggle-view-tags $tags
        done

        # Super+0 to focus all tags
        # Super+Shift+0 to tag focused view with all tags
        all_tags=$(((1 << 32) - 1))
        riverctl map normal Super 0 set-focused-tags $all_tags
        riverctl map normal Super+Shift 0 set-view-tags $all_tags

        systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
        dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=river
        systemctl --user restart xdg-desktop-portal

        killall .waybar-wrapped
        ${getExe pkgs.waybar} &
      '';
    };

    xdg.configFile = {
      "waybar/modules" = {
        recursive = true;
        source = ./modules;
      };
    };

    xdg = {
      portal = {
        enable = true;

        config = {
          river = {
            default = [ "gtk" ];
            "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
            "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
          };
        };
        extraPortals =
          with pkgs;
          map nixGL.wrap [
            xdg-desktop-portal
            xdg-desktop-portal-wlr
            xdg-desktop-portal-gtk
          ];
      };
    };
  };
}
