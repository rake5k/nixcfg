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

      policies = {
        PasswordManagerEnabled = false;
        DisableFirefoxAccounts = false;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableTelemetry = true;
        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
          EmailTracking = true;
        };
        FirefoxHome = {
          Search = true;
          TopSites = true;
          SponsoredTopSites = false;
          Highlights = false;
          Locked = true;
        };
        HomePage = {
          URL = cfg.homepage;
          StartPage = "homepage-locked";
          Locked = true;
        };
        HttpsOnlyMode = "force_enabled";
        OfferToSaveLogins = false;
        Preferences = {
          "browser.newtabpage.pinned" = [
            {
              label = "Blog";
              url = "https://blog.harke.ch";
            }
            {
              label = "Cloud";
              url = "https://cloud.harke.ch";
            }
            {
              label = "Code";
              url = "https://code.harke.ch";
            }
            {
              label = "News";
              url = "https://news.harke.ch";
            }
            {
              label = "ProtonMail";
              url = "https://mail.proton.me";
            }
          ];
          "browser.search.suggest.enabled" = false;
          "browser.search.region" = "CH";
          "cookiebanners.service.mode" = 1;
          "cookiebanners.service.mode.privateBrowsing" = 1;
        };
      };

      profiles."ztbvdcs8.default" = {
        inherit (cfg) extensions;

        isDefault = true;

        containers = {
          personal = {
            color = "turquoise";
            icon = "fingerprint";
            id = 1;
            name = "Personal";
          };
          personal_admin = {
            color = "pink";
            icon = "fingerprint";
            id = 2;
            name = "Personal Admin";
          };
          work = {
            color = "orange";
            icon = "briefcase";
            id = 3;
            name = "Work";
          };
          shopping = {
            color = "blue";
            icon = "cart";
            id = 4;
            name = "Shopping";
          };
          banking = {
            color = "green";
            icon = "dollar";
            id = 5;
            name = "Banking";
          };
          danger = {
            color = "red";
            icon = "fruit";
            id = 6;
            name = "Danger Zone";
          };
          Facebook = {
            color = "toolbar";
            icon = "fence";
            id = 7;
            name = "Facebook";
          };
        };
        containersForce = true;

        search =
          let
            engines = {
              harke = "Harke Search";
              nixPkgs = "Nix Packages";
              nixOpts = "NixOS Options";
              nixWiki = "NixOS Wiki";
            };
          in
          {
            default = "Harke Search";
            engines = {
              "${engines.harke}" = {
                urls = [{
                  template = "https://search.harke.ch/search";
                  params = [
                    { name = "q"; value = "{searchTerms}"; }
                  ];
                }];
                icon = ./icons/search.harke.ch.svg;
              };

              "${engines.nixPkgs}" = {
                urls = [{
                  template = "https://search.nixos.org/packages";
                  params = [
                    { name = "query"; value = "{searchTerms}"; }
                  ];
                }];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = [ "@np" ];
              };

              "${engines.nixOpts}" = {
                urls = [{
                  template = "https://search.nixos.org/options";
                  params = [
                    { name = "query"; value = "{searchTerms}"; }
                  ];
                }];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = [ "@no" ];
              };

              "${engines.nixWiki}" = {
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
            order = with engines; [
              harke
              nixPkgs
              nixOpts
              nixWiki
            ];
          };
      };
    };
  };
}
