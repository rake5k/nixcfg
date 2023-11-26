{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.web;

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
          consent-o-matic
          languagetool
          multi-account-containers
          new-tab-override
          onepassword-password-manager
          persistentpin
          proton-vpn
          tridactyl
          ublock-origin
        ];
      };
      roles.web.nextcloud-client.enable = true;
    };

    home.packages = with pkgs; [
      _1password
      _1password-gui
      bind
      thunderbird
      wget

      # Messengers
      signal-desktop
      telegram-desktop

      # Social Media
      freetube
    ];

    programs.chromium.enable = true;
  };
}
