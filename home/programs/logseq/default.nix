{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.programs.logseq;

in

{
  options = {
    custom.programs.logseq = {
      enable = mkEnableOption "Logseq";
    };
  };

  config = mkIf cfg.enable { home.packages = [ pkgs.logseq ]; };
}
