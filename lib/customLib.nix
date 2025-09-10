{
  lib,
  pkgs,
  inputs,
}:

inputs.flake-commons.lib {
  inherit lib pkgs;
  flake = inputs.self;
}
// (
  let
    inherit (lib)
      getExe
      literalExpression
      mkEnableOption
      mkOption
      types
      ;
  in
  rec {
    ntfyTokenSecret = "ntfy-token";
    ntfyUrlSecret = "ntfy-url";
    ntfyTopic = "chris-alerts";
    mkNtfyCommand =
      secretsCfg: body:
      let
        jsonBody = builtins.toJSON (body // { topic = ntfyTopic; });
        bodyFile = pkgs.writeText "ntfyBody" jsonBody;
      in
      ''
        ${getExe pkgs.curl} \
          -H "Authorization:Bearer $(${pkgs.coreutils}/bin/cat ${secretsCfg.${ntfyTokenSecret}.path})" \
          -H "Markdown: yes" \
          -H "Content-Type: application/json" \
          -d @'${bodyFile}' \
          "$(${pkgs.coreutils}/bin/cat ${secretsCfg.${ntfyUrlSecret}.path})"
      '';

    mkWindowManagerOptions = name: {
      enable = mkEnableOption "${name} window manager";

      modKey = mkOption {
        type = types.enum [
          "Super"
          "Alt"
        ];
        default = "Super";
        description = ''
          The window manager mod key.
        '';
      };

      autoruns = mkOption {
        type = with types; attrsOf int;
        default = { };
        description = ''
          Applications to be launched in a workspace of choice.
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
          default = pkgs.nerd-fonts.monofur;
          description = "Font derivation";
        };

        family = mkOption {
          type = types.str;
          default = "Monofur Nerd Font";
          description = "Font family";
        };

        pango = mkOption {
          type = types.str;
          default = "Monofur Nerd Font Bold 10";
          description = "Font config";
        };

        xft = mkOption {
          type = types.str;
          default = "Monofur Nerd Font:style=Bold:size=10:antialias=true";
          description = "Font config";
        };
      };

      isMobile = mkEnableOption "Enable laptop features";

      launcherCfg = {
        package = mkOption {
          type = types.package;
          description = "Launcher package to use";
        };

        launcherCmd = mkOption {
          type = types.str;
          description = "Command to spawn the application launcher";
        };
      };

      lockerCfg = {
        package = mkOption {
          type = types.package;
          description = "Locker package to use";
        };

        lockerCmd = mkOption {
          type = types.str;
          description = "Command for locking screen";
        };
      };

      passwordManager = {
        spawnCmd = mkOption {
          type = types.str;
          default = "${getExe pkgs._1password-gui}";
          description = "Command to spawn the default password manager";
        };
        wmClassName = mkOption {
          type = types.str;
          default = "1Password";
          description = "Window manager class name retrieved via `xprop` utility";
        };
      };

      screenshotCfg = {
        package = mkOption {
          type = types.package;
          description = "Screenshot util";
        };

        screenshotCmdFull = mkOption {
          type = types.str;
          description = "Command for taking full-screen screenshots";
        };

        screenshotCmdSelect = mkOption {
          type = types.str;
          description = "Command for taking selection screenshots";
        };

        screenshotCmdWindow = mkOption {
          type = types.str;
          description = "Command for taking window screenshots";
        };
      };

      terminalCfg = {
        package = mkOption {
          type = types.package;
          description = "Terminal emulator package";
        };

        spawnCmd = mkOption {
          type = types.str;
          description = "Command to spawn the default terminal emulator";
        };

        commandArgPrefix = mkOption {
          type = types.str;
          description = "Command argument prefix to spawn a shell command inside the default terminal emulator";
        };

        titleArgPrefix = mkOption {
          type = types.str;
          description = "Window title argument prefix";
        };
      };

      volumeCtl = {
        spawnCmd = mkOption {
          type = types.str;
          default = "${getExe pkgs.pavucontrol}";
          description = "Command to spawn the volume control utility";
        };
        wmClassName = mkOption {
          type = types.str;
          default = "pavucontrol";
          description = "Window manager class name retrieved via `xprop` utility";
        };
      };

      wallpaperCmd = mkOption {
        type = types.str;
        description = "Command to set the wallpaper";
      };

      wallpapersDir = mkOption {
        type = types.path;
        description = "Path to the wallpaper images";
      };

      wiki = {
        spawnCmd = mkOption {
          type = types.str;
          default = "${getExe pkgs.logseq}";
          description = "Command to spawn the default wiki app";
        };
        wmClassName = mkOption {
          type = types.str;
          default = "Logseq";
          description = "Window manager class name retrieved via `xprop` utility";
        };
      };
    };

    mkWritableFile = config: name: opts: {
      "${name}.hm-init" = opts // {
        onChange = ''
          rm -f ${config.home.file}/${name}
          cp ${config.home.file}/${name}.hm-init ${config.home.file}/${name}
          chmod u+w ${config.home.file}/${name}
        '';
      };
    };

    mkWritableConfigFile = config: name: opts: {
      "${name}.hm-init" = opts // {
        onChange = ''
          rm -f ${config.xdg.configHome}/${name}
          cp ${config.xdg.configHome}/${name}.hm-init ${config.xdg.configHome}/${name}
          chmod u+w ${config.xdg.configHome}/${name}
        '';
      };
    };
  }
)
