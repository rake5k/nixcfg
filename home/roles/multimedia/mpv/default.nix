{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.multimedia.mpv;

  scripts = {
    tv7 = pkgs.writeShellScriptBin "tv7"
      ''
        ${getExe pkgs.mpv} ${config.xdg.configFile."mpv/playlists".target}/TV7_default.m3u --script-opts=iptv=1
      '';
    tvsrg = pkgs.writeShellScriptBin "tvsrg"
      ''
        ${getExe pkgs.mpv} ${config.xdg.configFile."mpv/playlists".target}/srg-fhd-hls.m3u --script-opts=iptv=1
      '';
  };

in

{
  options = {
    custom.roles.multimedia.mpv = {
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
