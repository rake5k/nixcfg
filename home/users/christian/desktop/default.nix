{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.users.christian.desktop;

  inherit (lib) mkEnableOption mkIf optionals;
  inherit (pkgs.stdenv) isLinux;

in

{
  options = {
    custom.users.christian.desktop = {
      enable = mkEnableOption "Desktop";
    };
  };

  config = mkIf cfg.enable {
    custom = {
      roles = {
        desktop = {
          gtk.enable = isLinux;
          passwordManager.enable = isLinux;
          terminal.enable = true;
          wiki.enable = true;
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
      ];
  };
}
