{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.dev.intellij;
  ideaPackage =
    if cfg.ultimate then
      pkgs.unstable.jetbrains.idea-ultimate else
      pkgs.unstable.jetbrains.idea-community;

in

{
  options = {
    custom.roles.dev.intellij = {
      enable = mkEnableOption "IntelliJ";

      ultimate = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to Install the Ultimate Edition, Community Edition otherwise.";
      };
    };
  };

  config = mkIf cfg.enable {
    home = {
      file.".ideavimrc".text = ''
        Plug 'tpope/vim-surround'
        set ideajoin
        set clipboard+=unnamedplus
      '';

      packages = with pkgs; [
        ideaPackage
        (nerdfonts.override { fonts = [ "FiraCode" ]; })
      ];
    };
  };
}
