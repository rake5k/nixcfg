{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.programs.firefox;

in

{
  options = {
    custom.programs.firefox = {
      enable = mkEnableOption "Firefox web browser";

      extensions = mkOption {
        type = with types; listOf package;
        default = [ ];
        description = ''
          List of extension names to be installed. Source: https://gitlab.com/rycee/nur-expressions/-/blob/master/pkgs/firefox-addons/generated-firefox-addons.nix
        '';
      };

      homepage = mkOption {
        type = types.str;
        default = "https://harke.ch/";
        description = ''
          Home page for new tabs and windows.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    programs.firefox = {
      inherit (cfg) enable;

      profiles."ztbvdcs8.default" = {
        inherit (cfg) extensions;
        isDefault = true;
        settings = {
          "browser.search.suggest.enabled" = false;
          "browser.search.region" = "CH";
          "browser.startup.homepage" = cfg.homepage;
        };
        search = {
          default = "DuckDuckGo";
          engines = {
            "Nix Packages" = {
              urls = [{
                template = "https://search.nixos.org/packages";
                params = [
                  { name = "query"; value = "{searchTerms}"; }
                ];
              }];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@np" ];
            };

            "NixOS Options" = {
              urls = [{
                template = "https://search.nixos.org/options";
                params = [
                  { name = "query"; value = "{searchTerms}"; }
                ];
              }];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@no" ];
            };

            "NixOS Wiki" = {
              urls = [{
                template = "https://nixos.wiki/index.php";
                params = [
                  { name = "search"; value = "{searchTerms}"; }
                ];
              }];
              iconUpdateURL = "https://nixos.wiki/favicon.png";
              updateInterval = 24 * 60 * 60 * 1000; # every day
              definedAliases = [ "@nw" ];
            };

            "Amazon.de".metaData.hidden = true;
            "Bing".metaData.hidden = true;
            "eBay".metaData.hidden = true;
            "Google".metaData.hidden = true;
          };
          force = true;
        };
      };
    };
  };
}
