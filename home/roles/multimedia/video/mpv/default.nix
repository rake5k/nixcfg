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
