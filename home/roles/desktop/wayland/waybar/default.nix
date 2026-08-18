{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.desktop.wayland.waybar;

  inherit (lib)
    getExe
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  audioMuteToggle = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
  audioSourceMuteToggle = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
  fontPackage = pkgs.nerd-fonts.monofur;

  # Caffeine: a logind inhibitor lock held by a transient user unit. Lid-close
  # suspend only honors a `handle-lid-switch` lock (`LidSwitchIgnoreInhibited`
  # defaults to yes), so Wayland idle-inhibit cannot cover it. Host systemd
  # binaries are used on purpose: they match the running logind on non-NixOS.
  # wlinhibit additionally holds a Wayland idle-inhibit lock, since swayidle
  # only honors the compositor idle protocol, not logind idle inhibitors.
  caffeineStatus = pkgs.writeShellScript "caffeine-status" ''
    set -euo pipefail
    if systemctl --user --quiet is-active caffeine.service; then
      echo '{"text": "󰅶", "class": "activated", "tooltip": "Caffeine on: idle, sleep and lid-close inhibited"}'
    else
      echo '{"text": "󰾪", "class": "deactivated", "tooltip": "Caffeine off"}'
    fi
  '';

  caffeineToggle = pkgs.writeShellScript "caffeine-toggle" ''
    set -euo pipefail
    if systemctl --user --quiet is-active caffeine.service; then
      systemctl --user stop caffeine.service
    else
      systemd-run --user --unit=caffeine \
        --setenv=WAYLAND_DISPLAY="''${WAYLAND_DISPLAY}" \
        systemd-inhibit \
        --what=idle:sleep:handle-lid-switch --who=caffeine \
        --why="Caffeine toggled in waybar" ${pkgs.wlinhibit}/bin/wlinhibit
    fi
    pkill -RTMIN+8 -x waybar || true
  '';

in

{
  options = {
    custom.roles.desktop.wayland.waybar = {
      enable = mkEnableOption "Wayland status bar";

      isMobile = mkEnableOption "Enable laptop features";

      workspaceIndicator = mkOption {
        type = types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Name/label for the workspace indicator";
            };
            module = mkOption {
              type = types.attrs;
              default = { };
              description = "Module configuration for the workspace indicator";
            };
          };
        };
      };

      windowIndicator = mkOption {
        type = types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Name/label for the window indicator module";
            };
            module = mkOption {
              type = types.attrs;
              default = {
                format = "  {}";
                max-length = 90;
              };
              description = "Module configuration for the window indicator";
            };
          };
        };
      };

      volumeCtl = {
        spawnCmd = mkOption {
          type = types.str;
          description = "Command to spawn the volume control utility";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ fontPackage ];
    programs = {
      waybar = {
        enable = true;
        systemd.enable = true;

        settings = {
          mainBar = {
            layer = "top";
            modules-left = [
              "${cfg.workspaceIndicator.name}"
              "cpu"
              "memory"
              "disk"
              "temperature"
            ];
            modules-center = [ "${cfg.windowIndicator.name}" ];
            modules-right = [
              "power-profiles-daemon"
              "battery"
              "wireplumber"
              "clock"
              "custom/caffeine"
              "tray"
            ];

            # Modules

            "${cfg.workspaceIndicator.name}" = cfg.workspaceIndicator.module;

            cpu = {
              interval = 1;
              format = "  {}%";
              tooltip = false;
              on-click = "${getExe pkgs.gnome-system-monitor}";
            };

            memory = {
              interval = 1;
              format = "  {}%";
              tooltip = false;
              on-click = "${getExe pkgs.gnome-system-monitor}";
            };

            disk = {
              interval = 1;
              format = "  {percentage_used}%";
              path = "/";
            };

            temperature = {
              hwmon-path = "/sys/class/hwmon/hwmon1/temp1_input";
              input-filename = "temp1_input";
              format = " {temperatureC}°C";
            };

            "${cfg.windowIndicator.name}" = cfg.windowIndicator.module;

            # Hides itself when power-profiles-daemon is not on the system bus
            "power-profiles-daemon" = {
              format = "{icon}";
              tooltip-format = "Power profile: {profile}";
              format-icons = {
                default = "󰓅";
                performance = "󰓅";
                balanced = "󰾅";
                power-saver = "󰾆";
              };
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

            wireplumber = {
              tooltip = false;
              scroll-step = 5.0;
              format = "{icon}  {volume}% | {format_source}";
              format-icons = {
                default = [
                  ""
                  "󰖀"
                  "󰕾"
                ];
              };
              format-muted = "󰝟  0% | {format_source}";
              format-source = "󰍬 {volume}%";
              format-source-muted = "󰍭 0%";
              on-click = audioMuteToggle;
              on-click-middle = cfg.volumeCtl.spawnCmd;
              on-click-right = audioSourceMuteToggle;
            };

            clock = {
              interval = 1;
              format = "  {:%H:%M}";
              tooltip-format = "{:%Y-%m-%d}";
              on-click = "${getExe pkgs.gnome-clocks}";
              on-click-right = "${getExe pkgs.gnome-calendar}";
            };

            "custom/caffeine" = {
              exec = "${caffeineStatus}";
              return-type = "json";
              interval = 60;
              signal = 8;
              on-click = "${caffeineToggle}";
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
              margin-left: 12px;
              padding: 3px 12px;
              border-radius: 0 0 3px 3px;
              transition: none;
              background: @base00;
            }

            .modules-right {
                margin-right: 12px;
            }

            .module button {
              transition: none;
              color: @base03;
              background: transparent;
              border-radius: 0px;
              border-bottom: 3px solid transparent;
              padding: 2px 6px;
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

            /* niri/window keeps its module box visible when no window is active */
            window#waybar.empty #window {
              background: none;
              padding: 0;
            }

            #cpu {
              color: @base09;
            }

            #memory {
              color: @base0A;
            }

            #disk {
              color: @base0B;
            }

            #temperature {
              color: @base0E;
            }

            #tags, #workspaces {
              padding: 0;
            }

            #power-profiles-daemon {
              color: @base0C;
            }

            #battery {
              color: @base0B;
            }

            #battery.critical:not(.charging) {
              background-color: @base05;
              color: @base00;
              animation-name: blink;
              animation-duration: 0.5s;
              animation-timing-function: steps(12);
              animation-iteration-count: infinite;
              animation-direction: alternate;
            }

            @keyframes blink {
              to {
                background-color: @base08;
                color: @base05;
              }
            }

            #wireplumber {
              color: @base0A;
            }

            #clock {
              color: @base09;
            }

            #custom-caffeine {
              color: @base03;
            }

            #custom-caffeine.activated {
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
        fonts.override = {
          monospace = {
            package = fontPackage;
            name = "Monofur Nerd Font";
          };
        };
      };
    };
  };
}
