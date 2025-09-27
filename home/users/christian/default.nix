{
  config,
  lib,
  pkgs,
  ...
}:

let

  username = "christian";
  cfg = config.custom.users."${username}";

  inherit (lib) mkDefault mkEnableOption mkIf;

  nixAccessTokensSecret = "nix-access-tokens";

in

{
  options = {
    custom.users."${username}" = {
      enable = mkEnableOption "User config";
    };
  };

  config = mkIf cfg.enable {
    home = {
      username = mkDefault username;
    };

    custom = {
      roles.homeage = {
        enable = true;
        secrets = [ nixAccessTokensSecret ];
      };

      users."${username}" = {
        git.enable = true;
        gpg.enable = true;
        mobile.enable = config.custom.roles.mobile.enable;
        office.cli.enable = config.custom.roles.office.cli.enable;
        shell.enable = true;
        ssh.enable = true;
        steam.enable = config.custom.roles.gaming.enable;
        vim.enable = true;
        zed.enable = true;
      };
    };

    nix = {
      extraOptions = ''
        !include ${config.custom.roles.homeage.secretsPath}/${nixAccessTokensSecret}
      '';
    };

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
