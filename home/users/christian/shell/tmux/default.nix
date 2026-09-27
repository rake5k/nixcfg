{ config, lib, ... }:

let

  cfg = config.custom.users.christian.shell.tmux;

  inherit (lib) mkEnableOption mkIf;

in

{
  options = {
    custom.users.christian.shell.tmux = {
      enable = mkEnableOption "Tmux";
    };
  };

  config = mkIf cfg.enable {
    home.shellAliases = {
      mux = "tmuxinator";
    };

    programs.tmux = {
      enable = true;
      tmuxinator.enable = true;
      # Pass Shift+Enter through as a distinct key and OSC notifications to the outer terminal.
      extraConfig = ''
        set -g allow-passthrough on
        set -s extended-keys on
        set -as terminal-features 'xterm*:extkeys'
      '';
    };
  };
}
