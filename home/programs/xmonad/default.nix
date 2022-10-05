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

      xmobar = {
        enable = mkEnableOption "Xmobar";
        mobile = mkEnableOption "Enable additional mobile monitors";
      };
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        trayer
        cfg.dmenu.package
        cfg.font.package
        cfg.locker.package
        cfg.screenshot.package
      ];
    };

    programs.xmobar = {
      inherit (cfg.xmobar) enable;
      extraConfig = import ./xmobar.hs.nix { inherit lib pkgs cfg; };
    };

    xsession.windowManager.xmonad = {
      enable = true;
      enableContribAndExtras = true;
      config = import ./xmonad.hs.nix { inherit lib pkgs cfg; };
      extraPackages = mkIf cfg.xmobar.enable (with pkgs.haskellPackages; haskellPackages: [ xmobar ]);
    };
  };
}
