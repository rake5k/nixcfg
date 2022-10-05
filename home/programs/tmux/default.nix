{ config, lib, ... }:

with lib;

let

  cfg = config.custom.programs.tmux;

in

{
  options = {
    custom.programs.tmux = {
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
