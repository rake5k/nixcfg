{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  desktopCfg = config.custom.roles.desktop;
  terminalCfg = desktopCfg.terminal;
  xCfg = desktopCfg.xserver;
  cfg = xCfg.xmonad;

in

{
  options = {
    custom.roles.desktop.xserver.xmonad = {
      enable = mkEnableOption "Xmonad window manager";

      lightweight = mkEnableOption "Disable resource intensive effects";

      modKey = mkOption {
        type = types.enum [
          "mod1"
          "mod2"
          "mod4"
        ];
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

      launcherCmd = mkOption {
        type = types.str;
        default = "${pkgs.dmenu}/bin/dmenu_run";
        description = "Command to run dmenu";
      };

      locker = {
        package = mkOption {
          type = types.package;
          default = xCfg.locker.package;
          description = "Locker util";
        };

        lockCmd = mkOption {
          type = types.str;
          default = xCfg.locker.lockCmd;
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

        runCmdSelect = mkOption {
          type = types.str;
          default = "${./scripts/screenshot.sh} select";
          description = "Command for taking selection screenshots";
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

      wiki = {
        command = mkOption {
          type = types.str;
          description = "Command to spawn the default wiki app";
        };
        wmClassName = mkOption {
          type = types.str;
          description = "Window manager class name retrieved via `xprop` utility";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    custom = {
      roles.desktop.xserver = {
        dmenu = {
          enable = true;
          font = {
            inherit (desktopCfg.font) package;
          };
        };

        dunst = {
          enable = true;
          font = {
            inherit (desktopCfg.font) package family;
          };
        };

        picom.enable = !cfg.lightweight;

        polybar = {
          enable = true;
          inherit (xCfg) colorScheme;
          font = {
            inherit (desktopCfg.font) package;
            config = desktopCfg.font.xft;
          };
          height = 20;
          monitors.battery = desktopCfg.mobile.enable;
        };
      };
    };

    home = {
      packages = [
        cfg.locker.package
        cfg.screenshot.package
      ];
    };

    xsession.windowManager.xmonad = {
      enable = true;
      enableContribAndExtras = true;
      config = import ./xmonad.hs.nix {
        inherit
          lib
          pkgs
          cfg
          terminalCfg
          ;
      };
    };
  };
}
