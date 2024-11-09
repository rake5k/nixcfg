{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.desktop.gtk;

in

{
  options = {
    custom.roles.desktop.gtk = {
      enable = mkEnableOption "GTK";
    };
  };

  config = mkIf cfg.enable {
    gtk = {
      enable = true;
      iconTheme = {
        package = pkgs.paper-icon-theme;
        name = "Paper";
      };
      theme = {
        name = "Adwaita-dark";
      };
      gtk2.extraConfig = ''
        gtk-toolbar-style=GTK_TOOLBAR_BOTH
        gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
        gtk-button-images=1
        gtk-menu-images=1
        gtk-enable-event-sounds=1
        gtk-enable-input-feedback-sounds=1
        gtk-xft-antialias=1
        gtk-xft-hinting=1
        gtk-xft-hintstyle=hintfull
        gtk-xft-rgba=rgb'';
      gtk3 = {
        extraConfig = {
          gtk-application-prefer-dark-theme = 1;
          gtk-toolbar-style = "GTK_TOOLBAR_BOTH";
          gtk-toolbar-icon-size = "GTK_ICON_SIZE_LARGE_TOOLBAR";
          gtk-button-images = "1";
          gtk-menu-images = "1";
          gtk-enable-event-sounds = "0";
          gtk-enable-input-feedback-sounds = "0";
          gtk-xft-antialias = "1";
          gtk-xft-hinting = "1";
          gtk-xft-hintstyle = "hintfull";
          gtk-xft-rgba = "rgb";
        };
        bookmarks = [ "file://${config.home.homeDirectory}/Nextcloud" ];
      };
    };
  };
}
