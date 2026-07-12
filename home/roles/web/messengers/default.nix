{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.web.messengers;

  inherit (lib) mkEnableOption mkIf;

  # Chromium's keyring auto-detection only recognizes GNOME/KDE desktops, so
  # under niri Electron finds no backend ("System unsupported" dialog) even
  # though gnome-keyring provides org.freedesktop.secrets. Point it there
  # explicitly.
  element-desktop = pkgs.element-desktop.override {
    commandLineArgs = "--password-store=gnome-libsecret";
  };

in

{
  options = {
    custom.roles.web.messengers = {
      enable = mkEnableOption "Messengers";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      element-desktop
      threema-desktop
      (writeShellApplication {
        name = "element-private";
        runtimeInputs = [ element-desktop ];
        text = "element-desktop";
      })
      (writeShellApplication {
        name = "element-public";
        runtimeInputs = [ element-desktop ];
        text = "element-desktop --profile matrix";
      })
    ];
  };
}
