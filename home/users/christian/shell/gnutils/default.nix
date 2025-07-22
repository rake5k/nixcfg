{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.users.christian.shell.gnutils;

in

{
  options = {
    custom.users.christian.shell.gnutils = {
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
