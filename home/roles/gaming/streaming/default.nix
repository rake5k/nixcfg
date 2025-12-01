{
  config,
  lib,
  pkgs,
  ...
}:

let

  inherit (lib) mkEnableOption mkIf;

  cfg = config.custom.roles.gaming.streaming;

in

{
  options = {
    custom.roles.gaming.streaming = {
      enable = mkEnableOption "Game Streaming";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.moonlight-qt
    ];
  };
}
