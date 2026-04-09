{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.multimedia.books;

  inherit (lib) mkEnableOption mkIf;

  tiptoi-sync = pkgs.writeShellApplication {
    name = "tiptoi-sync";
    runtimeInputs = with pkgs; [
      rsync
    ];
    text = builtins.readFile ./scripts/tiptoi-sync.sh;
  };

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
        tiptoi-sync
      ];
    };
  };
}
