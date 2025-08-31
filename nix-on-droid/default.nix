{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:

let

  cfg = config.custom.base;

  inherit (lib) mkOption types;

in

{
  options = {
    custom.base = {
      hostname = mkOption {
        type = types.str;
        description = "Host name.";
      };
    };
  };

  config = {
    android-integration = {
      am.enable = true;
      termux-open.enable = true;
      termux-open-url.enable = true;
      termux-reload-settings.enable = true;
      termux-setup-storage.enable = true;
    };

    environment = {
      etcBackupExtension = ".nod-bak";
      motd = ''

          ___  (_)_ _________  ___  _______/ /______  (_)__/ /
         / _ \/ /\ \ /___/ _ \/ _ \/___/ _  / __/ _ \/ / _  /
        /_//_/_//_\_\    \___/_//_/    \_,_/_/  \___/_/\_,_/

      '';
    };

    home-manager.config = "${inputs.self}/hosts/${cfg.hostname}/home-nix-on-droid.nix";
    nix.package = pkgs.nix;

    stylix = {
      enable = true;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";
      fonts = {
        serif = {
          package = pkgs.dejavu_fonts;
          name = "DejaVu Serif";
        };

        sansSerif = {
          package = pkgs.nerd-fonts.monofur;
          name = "Monofur Nerd Font";
        };

        monospace = {
          package = pkgs.nerd-fonts.zed-mono;
          name = "ZedMono Nerd Font Mono";
        };
      };
      polarity = "dark";
    };

    time.timeZone = "Europe/Zurich";

    user.shell = "${pkgs.zsh}/bin/zsh";
  };
}
