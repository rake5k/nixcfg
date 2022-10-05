{ config, lib, pkgs, ... }:

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
        ranger.enable = true;
      };
    };

    home = {
      packages = with pkgs; [
        # Terminal fun
        asciiquarium
        bb
        cowsay
        cmatrix
        figlet
        fortune
        lolcat
        toilet

        # GNU util replacements
        fd # ultra-fast find
        ripgrep

        convmv
        eva
        file
        glow
        gnupg
        gron
        htop
        killall
        neofetch
        pandoc
        texlive.combined.scheme-small
        trash-cli
        unzip
      ];

      shellAliases = import ./aliases.nix;
    };

    programs = {
      ssh = import ./ssh.nix;
      zsh = import ./zsh.nix;

      bat.enable = true;
      exa.enable = true;
      fzf.enable = true;
      jq.enable = true;
      starship.enable = true;
    };
  };
}
