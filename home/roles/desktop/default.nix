{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.desktop;

in

{
  options = {
    custom.roles.desktop = {
      enable = mkEnableOption "Desktop";

      font = {
        package = mkOption {
          type = types.package;
          default = pkgs.nerdfonts.override { fonts = [ "VictorMono" ]; };
          description = "Font derivation";
        };

        family = mkOption {
          type = types.str;
          default = "VictorMono Nerd Font";
          description = "Font family";
        };

        familyMono = mkOption {
          type = types.str;
          default = "VictorMono Nerd Font Mono";
          description = "Mono Font family";
        };

        pango = mkOption {
          type = types.str;
          default = "VictorMono Nerd Font Bold 9";
          description = "Font config";
        };

        xft = mkOption {
          type = types.str;
          default = "VictorMono Nerd Font:style=Bold:size=9:antialias=true";
          description = "Font config";
        };
      };

      terminalCmd = mkOption {
        type = types.str;
        default = "${cfg.alacritty.spawnCmd}";
        description = "Command to spawn the default terminal emulator";
      };

      wallpapersDir = mkOption {
        type = types.path;
        default = config.home.homeDirectory + "/Pictures/wallpapers";
        description = "Directory containing wallpapers";
      };
    };
  };

  config = mkIf cfg.enable {

    custom.roles.desktop = {
      alacritty.enable = true;
      cursors.enable = true;
      dunst.enable = true;
      grobi.enable = true;
      gtk.enable = true;
      picom.enable = true;
      redshift.enable = true;
      xmonad.enable = true;
    };

    home = {
      packages = with pkgs; [
        gnome.pomodoro
        mupdf
        peek
        gifski
        xclip
        xzoom
      ];
    };

    xsession = {
      enable = true;
      numlock.enable = true;
    };
  };
}
