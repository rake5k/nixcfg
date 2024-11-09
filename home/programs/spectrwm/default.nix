{ config, lib, ... }:

with lib;

let

  cfg = config.custom.programs.spectrwm;

  mkAutorun = n: v: "autorun = ws[${toString v}]:${n}";

  baractionFile = "spectrwm/baraction.sh";
  screenshotFile = "spectrwm/screenshot.sh";
  initscrFile = "spectrwm/initscreen.sh";

in

{
  options.custom.programs.spectrwm = {
    enable = mkEnableOption "Spectrwm window manager";

    modKey = mkOption {
      type = types.enum [
        "Mod1"
        "Mod2"
        "Mod4"
      ];
      default = "Mod4";
      description = ''
        The window manager mod key.
        <itemizedList>
          <listItem>Alt key is <code>Mod1</code></listItem>
          <listItem>Apple key on OSX is <code>Mod2</code></listItem>
          <listItem>Windows key is <code>Mod4</code></listItem>
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

    font = {
      package = mkOption {
        type = types.package;
        default = pkgs.nerdfonts;
        description = "Font derivation";
      };

      xft = mkOption {
        type = types.str;
        default = "VictorMono Nerd Font:style=SemiBold:pixelsize=14:antialias=true";
        description = "Font config";
      };
    };

    dmenu = {
      package = mkOption {
        type = types.package;
        default = pkgs.dmenu;
        description = "dmenu derivation";
      };
    };

    locker = {
      package = mkOption {
        type = types.package;
        description = "Locker package";
      };

      lockCmd = mkOption {
        type = types.str;
        description = "Command to activate the locker";
      };
    };

    initscrScript = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Commands to initialize physical screens.
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Extra lines added to <filename>spectrwm.conf</filename> file.
      '';
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        # Baraction dependencies
        acpi
        lm_sensors
        scrot

        cfg.dmenu.package
        cfg.locker.package
        cfg.font.package

        # The window manager
        spectrwm
      ];
    };

    xdg.configFile =
      let
        binaryName = "spectrwm";
        reloadCmd = "killall -HUP ${binaryName}";
      in
      {
        "${baractionFile}" = {
          source = ./config/baraction.sh;
          executable = true;
          onChange = reloadCmd;
        };
        "${binaryName}/baraction/batt.sh" = {
          source = ./config/baraction/batt.sh;
          onChange = reloadCmd;
        };
        "${binaryName}/baraction/headset.sh" = {
          source = ./config/baraction/headset.sh;
          onChange = reloadCmd;
        };
        "${binaryName}/baraction/cpu.sh" = {
          source = ./config/baraction/cpu.sh;
          onChange = reloadCmd;
        };
        "${binaryName}/baraction/datetime.sh" = {
          source = ./config/baraction/datetime.sh;
          onChange = reloadCmd;
        };
        "${binaryName}/baraction/hdd.sh" = {
          source = ./config/baraction/hdd.sh;
          onChange = reloadCmd;
        };
        "${binaryName}/baraction/mem.sh" = {
          source = ./config/baraction/mem.sh;
          onChange = reloadCmd;
        };
        "${binaryName}/baraction/mic.sh" = {
          source = ./config/baraction/mic.sh;
          onChange = reloadCmd;
        };
        "${binaryName}/baraction/temp.sh" = {
          source = ./config/baraction/temp.sh;
          onChange = reloadCmd;
        };
        "${binaryName}/baraction/vol.sh" = {
          source = ./config/baraction/vol.sh;
          onChange = reloadCmd;
        };
        "${binaryName}/baraction/wifi.sh" = {
          source = ./config/baraction/wifi.sh;
          onChange = reloadCmd;
        };
        "${screenshotFile}" = {
          source = ./config/screenshot.sh;
          executable = true;
        };
        "${initscrFile}" = mkIf (cfg.initscrScript != "") {
          text = ''
            #!/usr/bin/env bash
            ${cfg.initscrScript}
          '';
          executable = true;
        };
        "${binaryName}/spectrwm.conf" = {
          text = ''
            workspace_limit         = 10
            # focus_mode              = default
            # focus_close             = previous
            # focus_close_wrap        = 1
            # focus_default           = last
            # spawn_position          = next
            # workspace_clamp         = 1
            # warp_focus              = 1
            # warp_pointer            = 1

            # Window Decoration
            border_width            = 2
            color_focus             = white
            # color_focus_maximized   = yellow
            # color_unfocus           = rgb:88/88/88
            # color_unfocus_maximized = rgb:88/88/00
            region_padding          = 10
            tile_gap                = 10

            # Region containment
            # Distance window must be dragged/resized beyond the region edge before it is
            # allowed outside the region.
            # boundary_width          = 50

            # Remove window border when bar is disabled and there is only one window in workspace
            # disable_border          = 1

            # Bar Settings
            # bar_enabled             = 1
            bar_border_width        = 4
            bar_border[1]           = black
            bar_border_unfocus[1]   = black
            # bar_color[1]            = black
            # bar_color_selected[1]   = rgb:00/80/80
            bar_font_color[1]       = white
            bar_font_color_selected = orange
            bar_font                = ${cfg.font.xft}
            bar_action              = ${config.xdg.configFile."${baractionFile}".target}
            bar_justify             = center
            bar_format              = +N:+I +S <+D+<>+4<+A+4<+V
            # workspace_indicator     = listcurrent,listactive,markcurrent,printnames
            # bar_at_bottom           = 0
            # stack_enabled           = 1
            clock_enabled           = 0
            # clock_format            = %a %b %d %R %Z %Y
            iconic_enabled          = 1
            maximize_hide_bar       = 1
            # window_class_enabled    = 0
            # window_instance_enabled = 0
            # window_name_enabled     = 0
            # verbose_layout          = 0
            # urgent_enabled          = 1

            # Dialog box size ratio when using TRANSSZ quirk; 0.3 < dialog_ratio <= 1.0
            # dialog_ratio            = 0.6

            # Split a non-RandR dual head setup into one region per monitor
            # (non-standard driver-based multihead is not seen by spectrwm)
            # region = screen[1]:1280x1024+0+0
            # region = screen[1]:1280x1024+1280+0

            # Launch applications in a workspace of choice
            ${concatStringsSep "\n" (mapAttrsToList mkAutorun cfg.autoruns)}

            # Customize workspace layout at start
            # format: ws[idx]:master_grow:master_add:stack_inc:always_raise:stack_mode
            layout = ws[2]:0:0:0:0:max
            layout = ws[3]:0:0:0:0:max
            layout = ws[6]:0:0:0:0:max
            layout = ws[9]:5:0:0:0:vertical

            # Set workspace name at start
            name = ws[1]:1 
            name = ws[2]:2 
            name = ws[3]:3 
            name = ws[4]:4 
            name = ws[5]:5 
            name = ws[6]:6 
            name = ws[9]:9 
            name = ws[10]:10 

            # Mod key, (Windows key is Mod4) (Apple key on OSX is Mod2)
            modkey = ${cfg.modKey}

            # This allows you to include pre-defined key bindings for your keyboard layout.
            # keyboard_mapping = ~/.spectrwm_us.conf
            bind[rg_next] = MOD+Shift+l
            bind[rg_prev] = MOD+Shift+h

            # PROGRAMS

            # Validated default programs:
            program[lock]           = ${cfg.locker.lockerCmd}
            program[term]           = alacritty
            # program[menu]           = dmenu_run $dmenu_bottom -fn $bar_font -nb $bar_color -nf $bar_font_color -sb $bar_color_selected -sf $bar_font_color_selected
            # program[search]         = dmenu $dmenu_bottom -i -fn $bar_font -nb $bar_color -nf $bar_font_color -sb $bar_color_selected -sf $bar_font_color_selected
            # program[name_workspace] = dmenu $dmenu_bottom -p Workspace -fn $bar_font -nb $bar_color -nf $bar_font_color -sb $bar_color_selected -sf $bar_font_color_selected

            # To disable validation of the above, free the respective binding(s):
            # bind[]    = MOD+Shift+Delete  # disable lock
            # bind[]    = MOD+Shift+Return  # disable term
            # bind[]    = MOD+p      # disable menu

            # Optional default programs that will only be validated if you override:
            program[screenshot_all]     = ${config.xdg.configFile."${screenshotFile}".target} full
            program[screenshot_wind]    = ${config.xdg.configFile."${screenshotFile}".target} window
            bind[screenshot_all]        = Print
            bind[screenshot_wind]       = Shift+Print
            ${concatStringsSep "\n" (
              optional (cfg.initscrScript != "") ''
                program[initscr]            = ${config.xdg.configFile."${initscrFile}".target}
              ''
            )}

            # EXAMPLE: Define 'firefox' action and bind to key.
            # program[firefox]    = firefox http://spectrwm.org/
            # bind[firefox]       = MOD+Shift+b

            # QUIRKS
            # Default quirks, remove with: quirk[class:name] = NONE
            # IDEA-Quirks not working somehow...
            # quirk[jetbrains-idea:win0]          = FLOAT
            # quirk[java-lang-Thread]             = FLOAT
            quirk[Microsoft Teams - Preview:Screen sharing toolbar] = FLOAT
            quirk[jetbrains-idea]               = WS[2]
            quirk[Microsoft Teams - Preview]    = WS[4]
            quirk[Signal]                       = WS[4]
            quirk[Slack]                        = WS[4]
            quirk[TelegramDesktop]              = WS[4]
            quirk[zoom]                         = WS[4]
            quirk[Daily]                        = WS[5]
            quirk[VirtualBox]                   = WS[6]
            quirk[VirtualBox Machine]           = WS[6]
            quirk[VirtualBox Manager]           = WS[6]
            quirk[xfreerdp]                     = WS[6]
            quirk[Steam]                        = WS[8]
            quirk[TeamSpeak 3]                  = WS[8]
            quirk[Spotify]                      = WS[9]

            ${cfg.extraConfig}
          '';
          onChange = reloadCmd;
        };
      };

    xsession = {
      enable = true;
      windowManager.command = "${pkgs.spectrwm}/bin/spectrwm";
    };
  };
}
