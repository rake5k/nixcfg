{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.programs.polybar;

  package = pkgs.polybar.override {
    pulseSupport = true;
  };

in

{
  options = {
    custom.programs.polybar = {
      enable = mkEnableOption "Polybar status bar";

      colorScheme = {
        foreground = mkOption {
          type = types.str;
          default = "#BBBBBB";
        };

        background = mkOption {
          type = types.str;
          default = "#000000";
        };

        base = mkOption {
          type = types.str;
          default = "#6586c8";
        };

        accent = mkOption {
          type = types.str;
          default = "#FF7F00";
        };

        warn = mkOption {
          type = types.str;
          default = "#FF5555";
        };
      };

      font = {
        package = mkOption {
          type = types.package;
          default = pkgs.nerdfonts;
          description = "Font derivation";
        };

        config = mkOption {
          type = types.str;
          default = "monospace";
          description = "Font config";
        };
      };

      height = mkOption {
        type = types.number;
        description = "Pixel height of the status bar";
      };

      monitors = {
        battery = mkEnableOption "Battery monitor";
        cpu = mkEnableOption "CPU monitor" // { default = true; };
        date = mkEnableOption "Date monitor" // { default = true; };
        disk = mkEnableOption "Disk monitor" // { default = true; };
        memory = mkEnableOption "Memory monitor" // { default = true; };
        temperature = mkEnableOption "Temperature monitor" // { default = true; };
        volume = mkEnableOption "Volume monitor" // { default = true; };
        weather = mkEnableOption "Weather monitor" // { default = true; };
      };
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        font-awesome
        networkmanagerapplet
        pasystray
      ];
    };

    services.polybar = {
      inherit package;

      enable = true;

      config = {
        "global/wm" = {
          # https://github.com/jaagr/polybar/wiki/Configuration#global-wm-settings
          margin-top = 0;
          margin-bottom = 0;
        };

        settings = {
          # Reload when the screen configuration changes (XCB_RANDR_SCREEN_CHANGE_NOTIFY event)
          screenchange-reload = false;

          # Compositing operators
          # @see: https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-operator-t
          compositing-background = "source";
          compositing-foreground = "over";
          compositing-overline = "over";
          compositing-underline = "over";
          compositing-border = "over";

          # Enables pseudo-transparency for the bar
          # If set to true the bar can be transparent without a compositor.
          pseudo-transparency = false;
        };

        colors = {
          background = "#000000";
          background-alt = "#373B41";
          foreground = "#C5C8C6";
          primary = "#F0C674";
          secondary = "#8ABEB7";
          alert = "#A54242";
          disabled = "#707880";

          # Bars
          bar-good = "#55aa55";
          bar-ok = "#557755";
          bar-warn = "#f5a70a";
          bar-alert = "#ff5555";
          bar-empty = "#444444";
        };

        "bar/top" = {
          inherit (cfg) height;

          enable-ipc = true;

          # Appearance
          monitor = "\${env:MONITOR}";
          monitor-strict = false;
          wm-restack = "generic";
          width = "100%:-20px";
          offset-x = "10px";
          offset-y = "5px";
          radius = 0;
          background = "\${colors.background}";
          foreground = "\${colors.foreground}";
          line-size = "2pt";
          padding-left = 0;
          padding-right = 1;
          font-0 = "${cfg.font.config};2";
          font-1 = "Font Awesome 6 Free,Font Awesome 6 Free Regular:style=Regular:size=9;2";
          fixed-center = true;

          # Modules
          module-margin = 1;
          modules-left = with cfg.monitors;
            concatStringsSep " " (
              [ "xworkspaces" ] ++
              (if cpu then [ "cpu" ] else [ ]) ++
              (if memory then [ "ram" ] else [ ]) ++
              (if disk then [ "dsk" ] else [ ]) ++
              (if temperature then [ "tmp" ] else [ ])
            );
          modules-center = "xwindow";
          modules-right = with cfg.monitors;
            concatStringsSep " " (
              (if weather then [ "wtr" ] else [ ]) ++
              (if volume then [ "vol" ] else [ ]) ++
              (if battery then [ "bat" ] else [ ]) ++
              (if date then [ "date" ] else [ ])
            );

          # Tray
          tray-position = "right";
          tray-detached = false;
          tray-maxsize = 16;
          tray-background = "\${colors.background}";
          tray-foreground = "\${colors.foreground}";
          tray-offset-x = 0;
          tray-offset-y = 0;
          tray-padding = 1;
          tray-scale = "1.0";
        };

        "module/xworkspaces" = {
          type = "internal/xworkspaces";

          pin-workspaces = false;
          enable-click = true;
          enable-scroll = true;
          reverse-scroll = true;

          label-active = "%name%";
          label-active-background = "\${colors.background-alt}";
          label-active-underline = "\${colors.primary}";
          label-active-padding = 1;

          label-occupied = "%name%";
          label-occupied-padding = 1;

          label-urgent = "%name%";
          label-urgent-background = "\${colors.alert}";
          label-urgent-padding = 1;

          label-empty = "%name%";
          label-empty-foreground = "\${colors.disabled}";
          label-empty-padding = 1;
        };

        "module/xwindow" = {
          type = "internal/xwindow";
          label = "%title:0:60:...%";
        };

        "module/cpu" = {
          type = "internal/cpu";
          interval = 2;

          # Format
          format-prefix = "CPU ";
          format-prefix-foreground = "\${colors.primary}";
          format = "<bar-load>";

          # Bar design
          bar-load-indicator = "";
          bar-load-width = 8;
          bar-load-foreground-0 = "\${colors.bar-good}";
          bar-load-foreground-1 = "\${colors.bar-ok}";
          bar-load-foreground-2 = "\${colors.bar-warn}";
          bar-load-foreground-3 = "\${colors.bar-alert}";
          bar-load-fill = "";
          bar-load-empty = "";
          bar-load-empty-foreground = "\${colors.bar-empty}";
        };

        "module/ram" = {
          type = "internal/memory";
          interval = 2;

          # Format
          format-prefix = "RAM ";
          format-prefix-foreground = "\${colors.primary}";
          format = "<bar-used>";

          # Bar design
          bar-used-indicator = "";
          bar-used-width = 8;
          bar-used-foreground-0 = "\${colors.bar-good}";
          bar-used-foreground-1 = "\${colors.bar-ok}";
          bar-used-foreground-2 = "\${colors.bar-warn}";
          bar-used-foreground-3 = "\${colors.bar-alert}";
          bar-used-fill = "";
          bar-used-empty = "";
          bar-used-empty-foreground = "\${colors.bar-empty}";
        };

        "module/dsk" = {
          type = "internal/fs";
          interval = 25;
          mount-0 = "/";

          # Format
          format-mounted-prefix = "DSK ";
          format-mounted-foreground = "\${colors.primary}";
          format-mounted = "<bar-used>";

          # Bar design
          bar-used-indicator = "";
          bar-used-width = 8;
          bar-used-foreground-0 = "\${colors.bar-good}";
          bar-used-foreground-1 = "\${colors.bar-ok}";
          bar-used-foreground-2 = "\${colors.bar-warn}";
          bar-used-foreground-3 = "\${colors.bar-alert}";
          bar-used-fill = "";
          bar-used-empty = "";
          bar-used-empty-foreground = "\${colors.bar-empty}";
        };

        "module/tmp" = {
          type = "internal/temperature";
          interval = 2;
          thermal-zone = 0;
          units = true;
          base-temperature = 20;
          warn-temperature = 65;

          # Format
          format = "<label>";
          format-prefix = "TMP ";
          format-prefix-foreground = "\${colors.primary}";
          label = "%temperature-c:2%";

          # Warn
          format-warn = "<label-warn>";
          format-warn-prefix = "TMP ";
          format-warn-prefix-foreground = "\${colors.primary}";
          label-warn = "%temperature-c:2%";
          label-warn-foreground = "\${colors.alert}";
        };

        "module/vol" = {
          type = "internal/pulseaudio";

          # Use PA_VOLUME_UI_MAX (~153%) if true, or PA_VOLUME_NORM (100%) if false
          use-ui-max = true;

          # Interval for volume increase/decrease (in percent points)
          interval = 5;

          # Interactions
          click-right = getExe pkgs.pavucontrol;

          # Default
          format-volume = "<label-volume> <bar-volume>";
          label-volume = "VOL";
          label-volume-foreground = "\${colors.primary}";

          # Muted
          format-muted = "<label-muted> <bar-volume>";
          format-muted-foreground = "\${colors.disabled}";
          label-muted = "VOL";

          # Bar design
          bar-volume-width = 8;
          bar-volume-gradient = false;
          bar-volume-indicator = "";
          bar-volume-fill = "─";
          bar-volume-empty = "─";
        };

        "module/bat" = {
          type = "internal/battery";
          full-at = 100;
          low-at = 15;
          battery = "BAT0";
          adapter = "AC";
          poll-interval = 5;

          # Charging
          animation-charging-0 = " ";
          animation-charging-1 = " ";
          animation-charging-2 = " ";
          animation-charging-3 = " ";
          animation-charging-4 = " ";
          animation-charging-framerate = 750;
          format-charging = "<animation-charging>";
          format-charging-prefix = "BAT ";
          format-charging-prefix-foreground = "\${colors.primary}";

          # Discharging
          format-discharging = "<ramp-capacity>";
          format-discharging-prefix = "BAT ";
          format-discharging-prefix-foreground = "\${colors.primary}";

          # Full
          format-full = "<ramp-capacity>";
          format-full-foreground = "\${colors.bar-good}";
          format-full-prefix = "BAT ";
          format-full-prefix-foreground = "\${colors.primary}";

          # Low
          format-low = "<ramp-capacity>";
          format-low-foreground = "\${colors.bar-alert}";
          format-low-prefix = "BAT ";
          format-low-prefix-foreground = "\${colors.primary}";

          # Ramp
          ramp-capacity-0 = " ";
          ramp-capacity-1 = " ";
          ramp-capacity-2 = " ";
          ramp-capacity-3 = " ";
          ramp-capacity-4 = " ";
        };

        "module/wtr" = {
          type = "custom/script";
          exec = "${getExe pkgs.bash} ${config.xdg.configFile."polybar/weather-plugin.sh".target}";
          tail = false;
          interval = 600;

          # Format
          format-prefix = "WTR ";
          format-prefix-foreground = "\${colors.primary}";
        };

        "module/date" = {
          type = "internal/date";
          interval = 1;
          date = "%a %b %d";
          time = "%H:%M";
          label = "%date% %time%";
          label-foreground = "\${colors.primary}";
        };
      };

      script = ''
        # Terminate already running bar instances
        ${package}/bin/polybar-msg cmd quit
        # Launch polybar
        export MONITOR=$(${getExe package} -m | ${getExe pkgs.gnugrep} '(primary)' | ${getExe pkgs.gnused} -e 's/:.*$//g')
        echo "Running polybar on $MONITOR"
        ${getExe package} top 2>${config.xdg.dataHome}/polybar/logs/top.log &
      '';
    };

    xdg = {
      configFile."polybar/weather-plugin.sh".text = import ./config/weather-plugin.nix { inherit lib pkgs; };
    };
  };
}
