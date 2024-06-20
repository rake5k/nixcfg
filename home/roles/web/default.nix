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
          simple-translate
          tridactyl
          ublacklist
          ublock-origin
        ];
      };
      roles.web.nextcloud-client.enable = isLinux;
    };

    home.packages = with pkgs; [
      _1password
      _1password-gui
      bind
      wget
    ]
    ++ optionals isLinux [
      # Messengers
      signal-desktop
      telegram-desktop
      threema-desktop

      # Social Media
      freetube
    ];

    programs.chromium.enable = isLinux;
  };
}
