{
  lib,
  config,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.gaming.comms;

in

{
  options = {
    custom.roles.gaming.comms = {
      enable = lib.mkEnableOption "Communication";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      discord
      teamspeak6-client
    ];
  };
}
