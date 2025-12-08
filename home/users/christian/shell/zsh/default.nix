{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.users.christian.shell.zsh;

  inherit (lib) mkEnableOption mkIf;

in

{
  options = {
    custom.users.christian.shell.zsh = {
      enable = mkEnableOption "Z shell";
    };
  };

  config =
    mkIf cfg.enable {
      programs.zsh = {
        enable = true;
        autosuggestion.enable = true;
        enableCompletion = true;
        autocd = true;
        dotDir = "${config.xdg.configHome}/zsh";
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
            path = "${config.programs.zsh.dotDir}/.zsh_history";
            save = historySize;
            share = true;
            size = historySize;
          };
        initContent = ''
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
    }
    // mkIf config.custom.base.non-nixos.enable {
      home = {
        packages = [
          pkgs.zsh
        ];

        # Set zsh as default shell on activation
        activation.make-zsh-default-shell = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          # if zsh is not the current shell
          PATH="/usr/bin:/bin:$PATH"
          ZSH_PATH="${config.home.homeDirectory}/.nix-profile/bin/zsh"
          if [[ $(getent passwd ${config.home.username}) != *"$ZSH_PATH" ]]; then
            echo "setting zsh as default shell (using chsh). password might be necessay."
            if grep -q $ZSH_PATH /etc/shells; then
              echo "adding zsh to /etc/shells"
              run echo "$ZSH_PATH" | sudo tee -a /etc/shells
            fi
            echo "running chsh to make zsh the default shell"
            run chsh -s $ZSH_PATH ${config.home.username}
            echo "zsh is now set as default shell !"
          fi
        '';
      };
    };
}
