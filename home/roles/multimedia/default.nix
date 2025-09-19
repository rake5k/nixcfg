{ config, lib, ... }:

let

  cfg = config.custom.roles.multimedia;

  inherit (lib) mkEnableOption mkIf;

in

{
  options = {
    custom.roles.multimedia = {
      enable = mkEnableOption "Multimedia";
    };
  };

  config = mkIf cfg.enable {
    custom.roles.multimedia = {
      books.enable = true;
      music.enable = true;
      video.enable = true;
    };
  };
}
