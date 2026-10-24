{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.multimedia.video.mpv;

  mkIptvScript = playlistFile: ''
    ${getExe pkgs.mpv} ${config.xdg.configHome}/mpv/playlists/${playlistFile} --script-opts=iptv=1
  '';

  scripts = {
    tv7 = pkgs.writeShellScriptBin "tv7" (mkIptvScript "TV7_default.m3u");
    tvsrg = pkgs.writeShellScriptBin "tvsrg" (mkIptvScript "srg-fhd-hls.m3u");
  };

in

{
  options = {
    custom.roles.multimedia.video.mpv = {
      enable = mkEnableOption "MPV";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      scripts.tv7
      scripts.tvsrg
    ];

    programs.mpv.enable = true;

    # Canonical shared-mime-info types plus the libmagic variants `xdg-open` detects
    xdg.mimeApps.defaultApplications = genAttrs [
      "audio/aac"
      "audio/flac"
      "audio/mp4"
      "audio/mpeg"
      "audio/ogg"
      "audio/vnd.wave"
      "audio/webm"
      "audio/x-aiff"
      "audio/x-ape"
      "audio/x-flac+ogg"
      "audio/x-hx-aac-adts"
      "audio/x-m4a"
      "audio/x-matroska"
      "audio/x-mpegurl"
      "audio/x-ms-wma"
      "audio/x-opus+ogg"
      "audio/x-scpls"
      "audio/x-vorbis+ogg"
      "audio/x-wav"
      "audio/x-wavpack"
      "video/3gpp"
      "video/MP2T"
      "video/mp2t"
      "video/mp4"
      "video/mpeg"
      "video/ogg"
      "video/quicktime"
      "video/vnd.avi"
      "video/webm"
      "video/x-flv"
      "video/x-matroska"
      "video/x-ms-asf"
      "video/x-ms-wmv"
      "video/x-msvideo"
      "video/x-theora+ogg"
    ] (_: "mpv.desktop");

    # Glob-based `xdg-open` types MPEG-TS `.ts` like TypeScript, which opens in an editor
    xdg.mimeApps.associations.added."text/vnd.trolltech.linguist" = "mpv.desktop";

    xdg.configFile = {
      "mpv/playlists" = {
        recursive = true;
        source = ./playlists;
      };
      "mpv/scripts" = {
        recursive = true;
        source = ./scripts;
      };
    };
  };
}
