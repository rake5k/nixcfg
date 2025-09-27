{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.users.christian.stylix;

  inherit (lib) mkEnableOption mkIf;

in

{
  options = {
    custom.users.christian.stylix.enable = mkEnableOption "Stylix";
  };

  config = mkIf cfg.enable {

    stylix = {
      enable = true;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";

      cursor = {
        package = pkgs.volantes-cursors;
        name = "volantes_cursors";
        size = 22;
      };

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

        emoji = {
          package = pkgs.noto-fonts-color-emoji;
          name = "Noto Color Emoji";
        };
      };

      opacity = {
        terminal = 0.8;
      };

      polarity = "dark";
    };
  };
}
