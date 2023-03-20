{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.programs.xmonad;

in

{
  options = {
    custom.programs.xmonad = {
      enable = mkEnableOption "Xmonad window manager";

      modKey = mkOption {
        type = types.enum [ "mod1" "mod2" "mod4" ];
        default = "mod4";
        description = ''
          The window manager mod key.
          <itemizedList>
            <listItem>Alt key is <code>mod1</code></listItem>
            <listItem>Apple key on OSX is <code>mod2</code></listItem>
            <listItem>Windows key is <code>mod4</code></listItem>
          <itemizedList>
        '';
      };

      autoruns = mkOption {
        type = with types; attrsOf int;
        default = { };
        description = ''
          applications to be launched in a workspace of choice.
        '';
        example = literalExpression ''
          {
            "firefox" = 1;
            "slack" = 2;
            "spotify" = 3;
          }
        '';
      };

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

        pango = mkOption {
          type = types.str;
          default = "VictorMono Nerd Font SemiBold 14";
          description = "Font config";
        };

        xft = mkOption {
          type = types.str;
          default = "monospace";
          description = "Font config";
        };
      };

      dmenu = {
        package = mkOption {
          type = types.package;
          default = pkgs.dmenu;
          description = "dmenu derivation";
        };

        runCmd = mkOption {
          type = types.str;
          default = "${pkgs.dmenu}/bin/dmenu_run";
          description = "Command to run dmenu";
        };
      };

      locker = {
        package = mkOption {
          type = types.package;
          default = pkgs.i3lock;
          description = "Locker util";
        };

        lockCmd = mkOption {
          type = types.str;
          default = "${pkgs.i3lock}/bin/i3lock";
          description = "Command for locking screen";
        };
      };

      screenshot = {
        package = mkOption {
          type = types.package;
          default = pkgs.scrot;
          description = "Screenshot util";
        };

        runCmdFull = mkOption {
          type = types.str;
          default = "${./scripts/screenshot.sh} full";
          description = "Command for taking full-screen screenshots";
        };

        runCmdWindow = mkOption {
          type = types.str;
          default = "${./scripts/screenshot.sh} window";
          description = "Command for taking window screenshots";
        };
      };

      passwordManager = {
        command = mkOption {
          type = types.str;
          description = "Command to spawn the default password manager";
        };
        wmClassName = mkOption {
          type = types.str;
          description = "Window manager class name retrieved via `xprop` utility";
        };
      };

      terminalCmd = mkOption {
        type = types.str;
        description = "Command to spawn the default terminal emulator";
      };

      statusbar = {
        enable = mkEnableOption "Enable status bar" // { default = true; };
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
        };
      };
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = [
        cfg.dmenu.package
        cfg.font.package
        cfg.locker.package
        cfg.screenshot.package
      ] ++ (with pkgs; [
        networkmanagerapplet
      ]);
    };

    services.polybar = {
      inherit (cfg.statusbar) enable;

      package = pkgs.polybar.override {
        pulseSupport = true;
      };

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
          inherit (cfg.statusbar) height;

          enable-ipc = true;

          # Appearance
          monitor = "\${env:MONITOR}";
          monitor-strict = false;
          wm-restack = "generic";
          width = "99.5%";
          offset-x = "0.3%";
          offset-y = 5;
          radius = 0;
          background = "\${colors.background}";
          foreground = "\${colors.foreground}";
          line-size = "2pt";
          padding-left = 0;
          padding-right = 1;
          font-0 = "${cfg.font.xft};2";
          fixed-center = true;

          # Modules
          module-margin = 1;
          modules-left = with cfg.statusbar.monitors;
            concatStringsSep " " (
              [ "xworkspaces" ] ++
              (if cpu then [ "cpu" ] else [ ]) ++
              (if memory then [ "ram" ] else [ ]) ++
              (if disk then [ "dsk" ] else [ ]) ++
              (if temperature then [ "tmp" ] else [ ])
            );
          modules-center = "xwindow";
          modules-right = with cfg.statusbar.monitors;
            concatStringsSep " " (
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
          click-right = "pavucontrol";

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
        polybar-msg cmd quit
        # Launch polybar
        MONITOR=$(polybar -m|grep '(primary)'|sed -e 's/:.*$//g') polybar top &
      '';
    };

    xsession.windowManager.xmonad = {
      enable = true;
      enableContribAndExtras = true;
      config = import ./xmonad.hs.nix { inherit lib pkgs cfg; };
    };
  };
}
