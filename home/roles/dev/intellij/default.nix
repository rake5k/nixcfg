{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.dev.intellij;

in

{
  options = {
    custom.roles.dev.intellij = {
      enable = mkEnableOption "IntelliJ config";

      install = mkEnableOption "Whether to install IntelliJ" // {
        default = true;
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
        ++ (optionals cfg.install [ jetbrains.idea-oss ]);
    };
  };
}
