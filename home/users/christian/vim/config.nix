{
  custom_plugins = [
    { repo = "lilydjwg/colorizer"; }
    { repo = "vimwiki/vimwiki"; }
  ];
  layers = [
    { name = "default"; }
    # VCS

    { name = "VersionControl"; }
    { name = "git"; }
    { name = "github"; }

    # Language

    {
      name = "autocomplete";
      auto_completion_return_key_behavior = "smart";
      auto_completion_tab_key_behavior = "smart";
      autocomplete_method = "coc";
    }

    {
      name = "lsp";
      filetypes = [
        "css"
        "docker"
        "elm"
        "haskell"
        "html"
        "java"
        "javascript"
        "json"
        "nix"
        "python"
        "rust"
        "sass"
        "scss"
        "sh"
        "typescript"
        "vue"
      ];
      override_cmd = {
        css = [ "vscode-css-language-server" ];
        docker = [ "docker-langserver" ];
        elm = [ "elm-language-server" ];
        haskell = [ "haskell-language-server-wrapper" ];
        html = [ "vscode-html-language-server" ];
        java = [ "jdt-language-server" ];
        json = [ "vscode-json-language-server" ];
        nix = [ "rnix-lsp" ];
        python = [ "pylsp" ];
        rust = [ "rust-analyzer" ];
        sass = [ "vscode-css-language-server" ];
        scss = [ "vscode-css-language-server" ];
        vue = [ "vls" ];
      };
    }

    { name = "lang#c"; }
    { name = "lang#dockerfile"; }
    { name = "lang#graphql"; }
    { name = "lang#haskell"; }
    { name = "lang#html"; }
    { name = "lang#java"; }
    { name = "lang#javascript"; }
    { name = "lang#latex"; }
    { name = "lang#markdown"; }
    { name = "lang#nix"; }
    { name = "lang#python"; }
    { name = "lang#rust"; }
    { name = "lang#toml"; }
    { name = "lang#typescript"; }
    { name = "lang#vim"; }
    { name = "lang#vue"; }
    { name = "lang#extra"; }

    # Utilities

    { name = "test"; }
    { name = "fzf"; }
    {
      default_height = 30;
      default_position = "top";
      name = "shell";
    }
    { name = "sudo"; }
    {
      enable = true;
      name = "colorscheme";
    }
  ];
  options = {
    buffer_index_type = 4;
    colorscheme = "onedark";
    colorscheme_bg = "dark";
    enable_guicolors = true;
    enable_statusline_mode = true;
    enable_tabline_filetype_icon = true;
    statusline_separator = "slant";
    timeoutlen = 500;
  };
}
