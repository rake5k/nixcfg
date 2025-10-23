{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.shell.gnutils;

  inherit (lib) mkEnableOption mkIf;

in

{
  options = {
    custom.roles.shell.gnutils = {
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

      shellAliases = {
        grep = "rg";
      };
    };
  };
}
