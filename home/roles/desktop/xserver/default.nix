{
  config,
  lib,
  pkgs,
  ...
}:

let

  desktopCfg = config.custom.roles.desktop;
  cfg = desktopCfg.xserver;

  inherit (lib)
    getExe
    literalExpression
    mkEnableOption
    mkIf
    mkOption
    optionalString
    types
    ;

  wallpaperCmd = "${getExe pkgs.feh} --no-fehbg --bg-fill --randomize ${cfg.wallpapersDir}";

  screenshotCfg = {
    package = pkgs.scrot;
    screenshotCmdFull = "${./scripts/screenshot.sh} full";
    screenshotCmdSelect = "${./scripts/screenshot.sh} select";
    screenshotCmdWindow = "${./scripts/screenshot.sh} window";
  };

in

{
  options = {
    custom.roles.desktop.xserver = {
      enable = mkEnableOption "X Server";

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

      wallpapersDir = mkOption {
        type = types.path;
        description = "Path to the wallpaper images";
      };
    };
  };

  config = mkIf cfg.enable {

    custom.roles.desktop.xserver = {
      grobi = {
        enable = true;
        inherit wallpaperCmd;
      };
      launcher.enable = true;
      locker = {
        enable = true;
        inherit (cfg) wallpapersDir;
      };
      redshift.enable = true;
      xbindkeys.enable = true;

      xmonad = {
        inherit screenshotCfg wallpaperCmd;
        inherit (cfg) autoruns;

        enable = true;
        launcherCfg = { inherit (cfg.launcher) package launcherCmd; };
        lockerCfg = { inherit (cfg.locker) package lockerCmd; };
        terminalCfg = {
          inherit (desktopCfg.terminal)
            package
            spawnCmd
            commandArgPrefix
            titleArgPrefix
            ;
        };
      };
    };

    home.packages = with pkgs; [
      peek
      gifski
      mupdf
      parcellite
      xclip
      xzoom
    ];

    xdg = {
      mime.enable = true;
      mimeApps.defaultApplications = {
        "inode/directory" = "org.gnome.Nautilus.desktop";
      };
    };

    xsession = {
      enable = true;
      initExtra = ''
        ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd --all
        ${optionalString (!cfg.grobi.enable) cfg.wallpaperCmd}
      '';
      numlock.enable = true;
    };
  };
}
