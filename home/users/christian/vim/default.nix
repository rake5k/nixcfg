{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.users.christian.vim;

in

{
  options = {
    custom.users.christian.vim = {
      enable = mkEnableOption "VIM config";
    };
  };

  config = mkIf cfg.enable {
    custom.users.christian.vim = {
      coc.enable = true;
    };

    home = {
      sessionVariables = {
        EDITOR = "vim";
      };
    };

    programs.neovim = {
      enable = true;
      withPython3 = false;
      withRuby = false;

      # lazygit.nvim shells out to the lazygit binary
      extraPackages = [ config.programs.lazygit.package ];

      initLua = ''
        vim.opt.clipboard = 'unnamedplus'
        vim.opt.cursorline = true
        vim.opt.relativenumber = true
        vim.opt.number = true
        vim.opt.foldmethod = 'marker'
        vim.opt.splitright = true
        vim.opt.splitbelow = true
        vim.opt.linebreak = true

        --------------
        -- SURROUND --
        --------------

        require('nvim-surround').setup({
          move_cursor = 'sticky'
        })

        --------------
        -- GITSIGNS --
        --------------

        require('gitsigns').setup({
          on_attach = function(bufnr)
            local gs = require('gitsigns')
            local function map(mode, l, r, desc)
              vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
            end

            -- Keep native ]c/[c in diff mode
            map('n', ']c', function()
              if vim.wo.diff then vim.cmd.normal({ ']c', bang = true }) else gs.nav_hunk('next') end
            end, 'Next hunk')
            map('n', '[c', function()
              if vim.wo.diff then vim.cmd.normal({ '[c', bang = true }) else gs.nav_hunk('prev') end
            end, 'Previous hunk')

            map('n', '<leader>hs', gs.stage_hunk, 'Stage hunk')
            map('n', '<leader>hr', gs.reset_hunk, 'Reset hunk')
            map('n', '<leader>hp', gs.preview_hunk, 'Preview hunk')
            map('n', '<leader>hb', function() gs.blame_line({ full = true }) end, 'Blame line')
            map('n', '<leader>hd', gs.diffthis, 'Diff against index')
          end,
        })

        -------------
        -- LAZYGIT --
        -------------

        vim.keymap.set('n', '<leader>gg', '<cmd>LazyGit<cr>', { silent = true, desc = 'LazyGit' })

        ----------------
        -- TREESITTER --
        ----------------

        -- nvim-treesitter's main-branch rewrite dropped the module system
        -- (`nvim-treesitter.configs`). Highlighting is now Neovim's built-in
        -- `vim.treesitter.start()` and indentation comes from the plugin's
        -- `indentexpr()`. Grammars/queries ship via Nix (withAllGrammars).
        vim.api.nvim_create_autocmd('FileType', {
          callback = function()
            pcall(vim.treesitter.start)
            vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end,
        })
      '';

      plugins = with pkgs.vimPlugins; [
        vim-nix

        # Git
        gitsigns-nvim
        lazygit-nvim

        # Markdown
        tabular
        vim-markdown

        # Misc
        nvim-surround
        nvim-treesitter.withAllGrammars
      ];

      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
    };

    # Canonical shared-mime-info types plus the libmagic variants `xdg-open` detects
    xdg.mimeApps.defaultApplications = genAttrs [
      "application/json"
      "application/sql"
      "application/toml"
      "application/x-perl"
      "application/x-ruby"
      "application/x-shellscript"
      "application/xml"
      "application/yaml"
      "text/css"
      "text/javascript"
      "text/markdown"
      "text/org"
      "text/plain"
      "text/rust"
      "text/vnd.trolltech.linguist"
      "text/x-c"
      "text/x-c++hdr"
      "text/x-c++src"
      "text/x-chdr"
      "text/x-cmake"
      "text/x-csrc"
      "text/x-go"
      "text/x-haskell"
      "text/x-java"
      "text/x-kotlin"
      "text/x-log"
      "text/x-lua"
      "text/x-makefile"
      "text/x-patch"
      "text/x-python"
      "text/x-python3"
      "text/x-rst"
      "text/x-scala"
      "text/x-script.python"
      "text/x-scss"
      "text/x-shellscript"
      "text/x-tex"
      "text/xml"
    ] (_: "nvim.desktop");
  };
}
