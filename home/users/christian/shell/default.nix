{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.users.christian.shell;

in

{
  options = {
    custom.users.christian.shell = {
      enable = mkEnableOption "Shell configuration and utils";
    };
  };

  config = mkIf cfg.enable {
    custom = {
      programs.tmux.enable = true;
      users.christian.shell = {
        direnv.enable = true;
        gnutils.enable = true;
        zsh.enable = true;
      };
    };

    home = {
      packages = with pkgs; [
        # Terminal fun
        asciiquarium
        cowsay
        cmatrix
        figlet
        fortune
        lolcat
        toilet

        # Make sure to have the right version in $PATH
        less

        curl
        eva
        file
        glow
        gron
        htop
        killall
        neofetch
        pandoc
        texlive.combined.scheme-small
        trash-cli
        unzip
      ];

      sessionVariables = {
        MANPAGER = "less -R --use-color -Dd+g -Du+b";
      };

      shellAliases = import ./aliases.nix {
        inherit lib;
        inherit (pkgs) stdenv;
      };
    };

    programs = {
      bat.enable = true;
      eza.enable = true;
      fzf.enable = true;
      jq.enable = true;
      starship = {
        enable = true;
        settings = {
          character = {
            success_symbol = "[➜](bold green)";
            error_symbol = "[➜](bold red)";
            vimcmd_symbol = "[V](bold green)";
          };
          nix_shell = {
            symbol = "❄ ";
          };
          package = {
            symbol = " ";
          };
        };
      };
      yazi.enable = true;
    };
  };
}
