{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let

  cfg = config.custom.roles.desktop;

  inherit (lib)
    literalExpression
    mkEnableOption
    mkIf
    mkOption
    types
    ;

in

{
  options = {
    custom.roles.desktop = {
      enable = mkEnableOption "Desktop";

      autoruns = mkOption {
        type = types.listOf config.lib.custom.autorunType;
        default = [ ];
        description = ''
          Applications to be launched in a workspace of choice.
        '';
        example = literalExpression ''
          [
            { command = "firefox"; workspace = 1; }
            { command = "slack"; workspace = 2; }
            { command = "spotify"; workspace= 3; }
          ]
        '';
      };

      wallpapersDir = mkOption {
        type = types.path;
        default = inputs.wallpapers;
        description = "Path to the wallpaper images";
      };
    };
  };

  config = mkIf cfg.enable {

    home.packages = with pkgs; [
      kooha
      mupdf
      seahorse
    ];

    services = {
      gnome-keyring.enable = true;
      network-manager-applet.enable = true;
    };

    xdg = {
      mime.enable = true;
      mimeApps = {
        enable = true;
        defaultApplications = {
          "inode/directory" = "org.gnome.Nautilus.desktop";
          "x-scheme-handler/http" = "firefox.desktop";
          "x-scheme-handler/https" = "firefox.desktop";
          "x-scheme-handler/chrome" = "firefox.desktop";
          "text/html" = "firefox.desktop";
          "application/x-extension-htm" = "firefox.desktop";
          "application/x-extension-html" = "firefox.desktop";
          "application/x-extension-shtml" = "firefox.desktop";
          "application/xhtml+xml" = "firefox.desktop";
          "application/x-extension-xhtml" = "firefox.desktop";
          "application/x-extension-xht" = "firefox.desktop";
          "x-scheme-handler/about" = "firefox.desktop";
          "x-scheme-handler/unknown" = "firefox.desktop";
        };
      };

      userDirs = {
        enable = true;
        createDirectories = true;
      };
    };
  };
}
