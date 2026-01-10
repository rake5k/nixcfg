{ config, lib, ... }:

let

  cfg = config.custom.users.christian.shell.lazygit;

  inherit (lib) mkEnableOption mkIf;

in

{
  options = {
    custom.users.christian.shell.lazygit = {
      enable = mkEnableOption "Lazygit";
    };
  };

  config = mkIf cfg.enable {
    home = {
      shellAliases = {
        lg = "lazygit";
      };
    };

    programs.lazygit = {
      enable = true;
    };
  };
}
