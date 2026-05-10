{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.users.christian.gpg;

in

{
  options = {
    custom.users.christian.gpg = {
      enable = mkEnableOption "GnuPG";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.gcr ];
    programs.gpg.enable = true;
  };
}
