{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.users.christian.shell;

  inherit (lib) mkEnableOption mkIf readFile;

in

{
  options = {
    custom.users.christian.shell = {
      enable = mkEnableOption "Shell configuration and utils";
    };
  };

  config = mkIf cfg.enable {
    custom = {
      users.christian.shell = {
        direnv.enable = true;
        lazygit.enable = true;
        starship.enable = true;
        tmux.enable = true;
        yazi.enable = true;
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

        curl
        eva
        file
        glow
        gron
        killall
        fastfetch
        trash-cli
        unzip
        # Breaks steam on SteamOS in desktop mode!
        # util-linux

        (writeShellApplication {
          name = "sbb";
          runtimeInputs = [
            coreutils
            curl
            jq
            miller
          ];
          text = readFile ./scripts/sbb.sh;
        })
      ];

      sessionVariables = {
        MANPAGER = "less -R --use-color -Dd+g -Du+b";
      };

      shellAliases = import ./aliases.nix {
        inherit lib;
        inherit (pkgs) stdenv;
      };

      shell.enableZshIntegration = true;
    };

    programs = {
      bat.enable = true;
      btop.enable = true;
      eza.enable = true;
      fzf.enable = true;
      htop.enable = true;
      jq.enable = true;
      less.enable = true;
      pandoc.enable = true;
    };
  };
}
