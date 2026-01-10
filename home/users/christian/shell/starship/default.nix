{ config, lib, ... }:

let

  cfg = config.custom.users.christian.shell.starship;

  inherit (lib) mkEnableOption mkIf;

in

{
  options = {
    custom.users.christian.shell.starship = {
      enable = mkEnableOption "Starship";
    };
  };

  config = mkIf cfg.enable {
    programs.starship = {
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
  };
}
