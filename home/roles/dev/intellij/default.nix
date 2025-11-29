{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.dev.intellij;
  ideaPackage = if cfg.ultimate then pkgs.jetbrains.idea-ultimate else pkgs.jetbrains.idea-community;

in

{
  options = {
    custom.roles.dev.intellij = {
      enable = mkEnableOption "IntelliJ config";

      install = mkEnableOption "Whether to install IntelliJ" // {
        default = true;
      };

      ultimate = mkOption {
        type = types.bool;
        default = false;
        description = "If installing, select the Ultimate Edition, Community Edition otherwise.";
      };
    };
  };

  config = mkIf cfg.enable {
    home = {
      file.".ideavimrc".text = ''
        Plug 'tpope/vim-surround'
        set ideajoin
        set clipboard+=unnamedplus
        set visualbell
        set nu rnu
      '';

      packages =
        with pkgs;
        [
          fira-code

          # language-servers
          nil
        ]
        ++ (optionals cfg.install [ ideaPackage ]);
    };
  };
}
