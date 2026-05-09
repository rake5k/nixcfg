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
              "battery"
              "wireplumber"
              "clock"
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
              padding: 6px 12px;
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
              padding: 4px 6px;
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

    xdg.configFile = {
      "waybar/modules" = {
        recursive = true;
        source = ./modules;
      };
    };
  };
}
