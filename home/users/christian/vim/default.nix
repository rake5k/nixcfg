{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.users.christian.vim;

  spacevim = pkgs.custom.spacevim.override {
    spacevim_config = import ./config.nix;
    bootstrap_before = builtins.readFile ./bootstrap_before.vim;
    bootstrap_after = builtins.readFile ./bootstrap_after.vim;
  };

  nvim-spell-de-utf8-dictionary = builtins.fetchurl {
    url = "http://ftp.vim.org/vim/runtime/spell/de.utf-8.spl";
    sha256 = "sha256:73c7107ea339856cdbe921deb92a45939c4de6eb9c07261da1b9dd19f683a3d1";
  };
  nvim-spell-en-utf8-dictionary = builtins.fetchurl {
    url = "http://ftp.vim.org/vim/runtime/spell/en.utf-8.spl";
    sha256 = "sha256:0w1h9lw2c52is553r8yh5qzyc9dbbraa57w9q0r9v8xn974vvjpy";
  };

in

{
  options = {
    custom.users.christian.vim = {
      enable = mkEnableOption "VIM config";
    };
  };

  config = mkIf cfg.enable {
    custom.programs.python = {
      enable = true;
      packages = with pkgs.python3Packages; [
        (buildPythonPackage rec {
          pname = "vimwiki-cli";
          version = "1.0.2";
          src = fetchPypi {
            inherit pname version;
            sha256 = "sha256-sqiNyUdskFGQrqt0vzYv20U5REoN9LzohK7l6fofowc=";
          };
          propagatedBuildInputs = [ click ];
          doCheck = false;
        })
      ];
    };

    home = {
      activation.clearSpaceVimConfigCache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD rm -f $VERBOSE_ARG \
        ${config.xdg.cacheHome}/SpaceVim/conf/init.json
      '';

      file =
        let
          inherit (config.lib.file) mkOutOfStoreSymlink;
          nixcfgDir = "${config.home.homeDirectory}/code/nixcfg";
          nixcfgDictionaryDir = "${nixcfgDir}/home/users/christian/vim/data/spell";
          spellConfDir = "${config.xdg.configHome}/nvim/spell";
          spellDataDir = "${config.xdg.dataHome}/nvim/site/spell";
          format = pkgs.formats.toml { };
        in
        {
          "${spellConfDir}/de.utf-8.spl".source = nvim-spell-de-utf8-dictionary;
          "${spellConfDir}/en.utf-8.spl".source = nvim-spell-en-utf8-dictionary;
          "${spellDataDir}/shared.utf-8.add".source = mkOutOfStoreSymlink "${nixcfgDictionaryDir}/shared.utf-8.add";
          "${spellDataDir}/de.utf-8.add".source = mkOutOfStoreSymlink "${nixcfgDictionaryDir}/de.utf-8.add";
          "${spellDataDir}/en.utf-8.add".source = mkOutOfStoreSymlink "${nixcfgDictionaryDir}/en.utf-8.add";
        };

      packages = with pkgs; [
        # TODO:
        # - spell config
        # - vimwiki config
        # see: https://spacevim.org/documentation/#bootstrap-functions
        spacevim

        # LSP servers
        elmPackages.elm-language-server
        haskell-language-server
        jdt-language-server
        nodePackages.bash-language-server
        nodePackages.dockerfile-language-server-nodejs
        nodePackages.typescript-language-server
        nodePackages.vscode-langservers-extracted
        nodePackages.vue-language-server
        nodePackages.yaml-language-server
        python310Packages.python-lsp-server
        rnix-lsp
        rust-analyzer
      ];

      sessionVariables = {
        EDITOR = "spacevim";
      };

      shellAliases = {
        vi = "spacevim";
        vim = "spacevim";
      };
    };

    xdg.dataFile = {
      "nvim/site/dict/mthesaur.txt".source = ./data/dict/mthesaur.txt;
      "nvim/site/dict/openthesaurus.txt".source = ./data/dict/openthesaurus.txt;
    };
  };
}
