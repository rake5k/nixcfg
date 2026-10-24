{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.users.christian.web;

  inherit (lib) mkEnableOption mkIf optionals;
  inherit (pkgs.stdenv.hostPlatform) isLinux;

in

{
  options = {
    custom.users.christian.web = {
      enable = mkEnableOption "Web";
    };
  };

  config = mkIf cfg.enable {
    home.packages = optionals isLinux [ pkgs.protonmail-desktop ];

    xdg.mimeApps.defaultApplications."x-scheme-handler/mailto" = "proton-mail.desktop";
  };
}
