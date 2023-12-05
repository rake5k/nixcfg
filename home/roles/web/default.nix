{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.web;

  inherit (config.custom.base.non-nixos) isDarwin;

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
        enable = !isDarwin;
        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          facebook-container
          istilldontcareaboutcookies
          languagetool
          multi-account-containers
          new-tab-override
          onepassword-password-manager
          persistentpin
          proton-vpn
          simple-translate
          tridactyl
          ublock-origin
        ];
      };
      roles.web.nextcloud-client.enable = !isDarwin;
    };

    home.packages = with pkgs; [
      _1password
      _1password-gui
      bind
      wget
    ]
    ++ optionals (!isDarwin) [
      # Messengers
      signal-desktop
      telegram-desktop
      threema-desktop

      # Social Media
      freetube
    ];

    programs.chromium.enable = !isDarwin;
  };
}
