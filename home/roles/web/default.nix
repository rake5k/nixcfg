{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.web;

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
        # See: https://github.com/NixOS/nixpkgs/issues/71689
        enable = isLinux;
        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          facebook-container
          istilldontcareaboutcookies
          languagetool
          localcdn
          multi-account-containers
          onepassword-password-manager
          persistentpin
          proton-vpn
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

    home.packages = with pkgs; [
      unstable._1password
      unstable._1password-gui
      bind
      unstable.protonmail-desktop
      wget
    ];

    programs.chromium = {
      enable = isLinux;
      package = pkgs.chromium.override { enableWideVine = true; };
    };
  };
}
