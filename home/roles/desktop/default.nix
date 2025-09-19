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
    optionals
    types
    ;
  inherit (pkgs.stdenv) isLinux;

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

    custom = {
      roles = {
        desktop = {
          gtk.enable = isLinux;
          passwordManager.enable = isLinux;
          terminal.enable = true;
          wayland = {
            inherit (cfg) autoruns wallpapersDir;
          };
          wiki.enable = true;
          xserver = {
            inherit (cfg) autoruns wallpapersDir;
          };
        };
      };
    };

    home.packages =
      with pkgs;
      optionals isLinux [
        gnome-characters
        gnome-pomodoro
        nautilus
        quickemu
        seahorse
      ];

    services.gnome-keyring.enable = isLinux;

    xdg.userDirs = mkIf isLinux {
      enable = true;
      createDirectories = true;
    };
  };
}
