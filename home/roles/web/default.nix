{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.web;

  inherit (lib) mkEnableOption mkIf optionals;
  inherit (pkgs.stdenv) isLinux;

in

{
  options = {
    custom.roles.web = {
      enable = mkEnableOption "Web";
    };
  };

  config = mkIf cfg.enable {
    custom = {
      programs.firefox = {
        enable = true;
        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          facebook-container
          istilldontcareaboutcookies
          languagetool
          libredirect
          localcdn
          multi-account-containers
          onepassword-password-manager
          tridactyl
          ublacklist
          ublock-origin
        ];
      };

      roles.web = {
        freetube.enable = isLinux;
        messengers.enable = isLinux;
      };
    };

    home.packages =
      with pkgs;
      [
        bind
        wget
      ]
      ++ (optionals isLinux [
        protonmail-desktop
      ]);

    programs.chromium = {
      enable = isLinux;
      package = pkgs.chromium.override { enableWideVine = true; };
    };
  };
}
