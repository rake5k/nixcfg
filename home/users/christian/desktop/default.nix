{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.users.christian.desktop;

  inherit (lib)
    genAttrs
    mkEnableOption
    mkIf
    optionals
    ;
  inherit (pkgs.stdenv.hostPlatform) isLinux;

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
        multimedia.video.mpv.enable = true;
      };
    };

    home.packages =
      with pkgs;
      optionals isLinux [
        gnome-characters
        gnome-pomodoro
        imv
        mupdf
        nemo-with-extensions
        quickemu
      ];

    # Nemo's "Open in Terminal" reads Cinnamon's default terminal
    dconf.settings = mkIf isLinux {
      "org/cinnamon/desktop/default-applications/terminal" = {
        exec = config.custom.roles.desktop.terminal.spawnCmd;
        exec-arg = "";
      };
    };

    xdg.mimeApps.defaultApplications = {
      "inode/directory" = "nemo.desktop";
    }
    // genAttrs [
      "application/epub+zip"
      "application/oxps"
      "application/pdf"
      "application/vnd.comicbook+zip"
      "application/vnd.ms-xpsdocument"
    ] (_: "mupdf.desktop")
    # Canonical shared-mime-info types plus the libmagic variants `xdg-open` detects
    // genAttrs [
      "image/avif"
      "image/bmp"
      "image/gif"
      "image/heic"
      "image/heif"
      "image/jpeg"
      "image/jxl"
      "image/png"
      "image/qoi"
      "image/svg+xml"
      "image/tiff"
      "image/webp"
      "image/x-farbfeld"
      "image/x-qoi"
    ] (_: "imv.desktop");
  };
}
