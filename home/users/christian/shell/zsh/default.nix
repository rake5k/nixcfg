{ config, lib, pkgs, ... }:

with lib;

{
  home = {
    file = {
      "${config.programs.zsh.dotDir}/completions".source = ./completions;
    };
  };

  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    enableSyntaxHighlighting = true;
    autocd = true;
    dotDir = ".config/zsh";
    dirHashes = {
      bb = "/mnt/bluecare/bluecare";
      bh = "/mnt/bluecare/home";
      bt = "/mnt/bluecare/transfer";
      d = "$HOME/Documents";
      dl = "$HOME/Downloads";
      hh = "/mnt/home/home";
      hm = "/mnt/home/music";
      hp = "/mnt/home/photo";
      ht = "/mnt/home/public";
      hv = "/mnt/home/video";
      p = "$HOME/Pictures";
      usb = "/run/media/chr";
      v = "$HOME/Videos";
    };
    history =
      let
        historySize = 1000000;
      in
      {
        expireDuplicatesFirst = true;
        extended = true;
        ignoreDups = true;
        ignoreSpace = true;
        path = "$ZDOTDIR/.zsh_history";
        save = historySize;
        share = true;
        size = historySize;
      };
    initExtraBeforeCompInit = ''
      fpath=(~/.zsh/completion $fpath)
    '';
    shellGlobalAliases = {
      "..." = "../..";
      "...." = "../../..";
      "....." = "../../../..";
      "......" = "../../../../..";
      "......." = "../../../../../..";
      "........" = "../../../../../../..";
      G = "| grep";
      UUID = "$(uuidgen | tr -d \\n)";
    };
  };
}
