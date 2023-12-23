{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.users.christian.shell.zsh;

in

{
  options = {
    custom.users.christian.shell.zsh = {
      enable = mkEnableOption "Z shell";
    };
  };

  config = mkIf cfg.enable {
    programs.zsh = {
      enable = true;
      enableAutosuggestions = true;
      enableCompletion = true;
      autocd = true;
      completionInit = optionalString config.lib.custom.sys.isDarwin "autoload -U compinit && compinit -u";
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
      initExtra = ''
        # Fix for https://superuser.com/questions/997593/why-does-zsh-insert-a-when-i-press-the-delete-key
        bindkey "^[[3~" delete-char
        # Fix for https://stackoverflow.com/questions/43249043/bind-delete-key-in-vi-mode
        bindkey -a '^[[3~' vi-delete-char
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
      syntaxHighlighting.enable = true;
    };
  };
}
