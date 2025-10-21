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
    };
  };
}
