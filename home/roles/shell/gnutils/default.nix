{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.shell.gnutils;

  inherit (lib) mkEnableOption mkIf;

in

{
  options = {
    custom.shell.gnutils = {
      enable = mkEnableOption "GNU utils and replacements";
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [

        # GNU utils
        coreutils
        gawk
        gnugrep
        gnupg
        gnused
        gnutar

        # GNU util replacements
        fd # ultra-fast find
        ripgrep
      ];
    };
  };
}
