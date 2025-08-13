{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.multimedia.books;

  inherit (lib) mkEnableOption mkIf;

in

{
  options = {
    custom.roles.multimedia.books = {
      enable = mkEnableOption "Books";
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        calibre
      ];
    };
  };
}
