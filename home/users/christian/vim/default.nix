{ config, lib, pkgs, machNix, ... }:

with lib;
with builtins;

let

  cfg = config.custom.users.christian.vim;

  nvim-spell-de-utf8-dictionary = fetchurl {
    url = "http://ftp.vim.org/vim/runtime/spell/de.utf-8.spl";
    sha256 = "sha256:73c7107ea339856cdbe921deb92a45939c4de6eb9c07261da1b9dd19f683a3d1";
  };
  nvim-spell-en-utf8-dictionary = fetchurl {
    url = "http://ftp.vim.org/vim/runtime/spell/en.utf-8.spl";
    sha256 = "sha256:0w1h9lw2c52is553r8yh5qzyc9dbbraa57w9q0r9v8xn974vvjpy";
  };

  vimwiki-cli = machNix.buildPythonPackage {
    pname = "vimwiki-cli";
    version = "1.0.0";
    requirements = ''
      click~=7.1
      setuptools
      wheel
    '';
    src = fetchGit {
      url = "https://github.com/sstallion/vimwiki-cli";
      ref = "refs/tags/v1.0.0";
      rev = "6e7689e052d1462d950e6af19964c97827216e64";
    };
  };

in

{
  options = {
    custom.users.christian.vim = {
      enable = mkEnableOption "VIM config";
    };
  };

  config = mkIf cfg.enable {
    home = {
      file =
        let
          inherit (config.lib.file) mkOutOfStoreSymlink;
          nixcfgDir = "${config.home.homeDirectory}/code/nixcfg";
          nixcfgDictionaryDir = "${nixcfgDir}/home/users/christian/vim/data/spell";
          spellConfDir = "${config.xdg.configHome}/nvim/spell";
          spellDataDir = "${config.xdg.dataHome}/nvim/site/spell";
        in
        {
          "${spellConfDir}/de.utf-8.spl".source = nvim-spell-de-utf8-dictionary;
          "${spellConfDir}/en.utf-8.spl".source = nvim-spell-en-utf8-dictionary;
          "${spellDataDir}/shared.utf-8.add".source = mkOutOfStoreSymlink "${nixcfgDictionaryDir}/shared.utf-8.add";
          "${spellDataDir}/de.utf-8.add".source = mkOutOfStoreSymlink "${nixcfgDictionaryDir}/de.utf-8.add";
          "${spellDataDir}/en.utf-8.add".source = mkOutOfStoreSymlink "${nixcfgDictionaryDir}/en.utf-8.add";
        };

      packages = [
        pkgs.custom.neovim
        vimwiki-cli
      ];

      sessionVariables = {
        EDITOR = "vim";
      };
    };

    xdg.dataFile = {
      "nvim/site/dict/mthesaur.txt".source = ./data/dict/mthesaur.txt;
      "nvim/site/dict/openthesaurus.txt".source = ./data/dict/openthesaurus.txt;
    };
  };
}
