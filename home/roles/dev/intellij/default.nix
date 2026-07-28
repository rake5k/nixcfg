{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.dev.intellij;

  # JetBrains ships a single unified IDEA distribution since 2025.3; the former
  # Ultimate/Community split is now `jetbrains.idea` (unfree, paid features
  # unlocked by licence) vs `jetbrains.idea-oss` (community-equivalent build).
  # See: https://blog.jetbrains.com/idea/2025/07/intellij-idea-unified-distribution-plan/
  ideaPackage = if cfg.ultimate then pkgs.jetbrains.idea else pkgs.jetbrains.idea-oss;

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
        description = "If installing, select the unified distribution, the OSS build otherwise.";
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
          nixfmt
        ]
        ++ (optionals cfg.install [ ideaPackage ]);
    };
  };
}
