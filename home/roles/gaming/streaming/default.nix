{
  config,
  lib,
  pkgs,
  ...
}:

let

  inherit (lib) mkEnableOption mkIf;

  cfg = config.custom.roles.gaming.streaming;

  moonlight = config.lib.nixGL.wrap pkgs.moonlight-qt;

in

{
  options = {
    custom.roles.gaming.streaming = {
      enable = mkEnableOption "Game Streaming";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      moonlight
    ];
  };
}
