{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.users.christian.gpg;

  pinentryPkg = if pkgs.stdenv.isDarwin then pkgs.pinentry_mac else pkgs.pinentry-gnome3;

in

{
  options = {
    custom.users.christian.gpg = {
      enable = mkEnableOption "GnuPG";
    };
  };

  config = mkIf cfg.enable {
    programs.gpg.enable = true;

    services.gpg-agent.pinentry.package = pinentryPkg;
  };
}
