{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.users.christian.vim.coc;

in

{
  options = {
    custom.users.christian.vim.coc = {
      enable = mkEnableOption "VIM coc plugin config";
    };
  };

  config = mkIf cfg.enable (
    let
      systemd-language-server =
        with pkgs;
        python3Packages.buildPythonPackage {
          pname = "systemd-language-server";
          version = "0.3.5";
          format = "wheel";
          src = fetchurl {
            url = "https://files.pythonhosted.org/packages/72/38/4526913c9a2b314eec0deea826c0349b8790c6123c387e796c999cf25015/systemd_language_server-0.3.5.tar.gz";
            hash = "sha256-D6EivoBduNvwqGuGGPcjetUJlYbcCzFZDptwj0WGD5w=";
          };
        };
    in
    {
      programs.neovim = {
        extraPackages = with pkgs; [
          # formatters
          black
          nixfmt-rfc-style
          shfmt
        ];

        plugins = with pkgs.vimPlugins; [
          coc-html
          coc-java
          coc-json
          coc-markdownlint
          coc-pyright
          coc-sh
          coc-tsserver
          coc-vetur
        ];

        coc = {
          enable = true;
          settings = {
            coc.preferences = {
              formatOnSave = true;
            };
            semanticTokens = {
              filetypes = [ "nix" ];
            };
            languageserver = {
              dockerfile = {
                command = "${pkgs.dockerfile-language-server-nodejs}/bin/docker-langserver";
                filetypes = [ "dockerfile" ];
                args = [ "--stdio" ];
              };
              dockercompose = {
                command = "${pkgs.docker-compose-language-service}/bin/docker-compose-langserver";
                args = [ "--stdio" ];
                filetypes = [ "dockercompose" ];
                rootPatterns = [
                  ".git"
                  ".env"
                  "docker-compose.yml"
                  "compose.yml"
                ];
              };
              efm = {
                command = "${pkgs.efm-langserver}/bin/efm-langserver";
                args = [ ];
                filetypes = [
                  "markdown"
                  "vim"
                ];
              };
              nix = {
                command = "${pkgs.nil}/bin/nil";
                filetypes = [ "nix" ];
                rootPatterns = [ "flake.nix" ];
                settings = {
                  nil = {
                    formatting = {
                      command = [ "nixfmt" ];
                    };
                  };
                };
              };
              systemd-language-server = {
                command = "${systemd-language-server}/bin/systemd-language-server";
                filetypes = [ "systemd" ];
              };
            };
            java = {
              enabled = true;
            };
            pyright = {
              enable = true;
            };
          };
        };

        extraConfig = ''
          set shiftwidth=2 softtabstop=2 expandtab

          """"""""""""""""""""
          "" Docker Compose ""
          """"""""""""""""""""

          au FileType yaml if bufname("%") =~# "docker-compose.yml" | set ft=yaml.docker-compose | endif
          au FileType yaml if bufname("%") =~# "compose.yml" | set ft=yaml.docker-compose | endif

          let g:coc_filetype_map = {
            \ 'yaml.docker-compose': 'dockercompose',
            \ }
        '';

        extraLuaConfig = ''
          ---------
          -- COC --
          ---------

          -- Some servers have issues with backup files, see #649
          vim.opt.backup = false
          vim.opt.writebackup = false

          -- Having longer updatetime (default is 4000 ms = 4s) leads to noticeable
          -- delays and poor user experience
          vim.opt.updatetime = 300

          -- Always show the signcolumn, otherwise it would shift the text each time
          -- diagnostics appeared/became resolved
          vim.opt.signcolumn = "yes"

          local keyset = vim.keymap.set
          -- Autocomplete
          function _G.check_back_space()
              local col = vim.fn.col('.') - 1
              return col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') ~= nil
          end

          -- Use Tab for trigger completion with characters ahead and navigate
          -- NOTE: There's always a completion item selected by default, you may want to enable
          -- no select by setting `"suggest.noselect": true` in your configuration file
          -- NOTE: Use command ':verbose imap <tab>' to make sure Tab is not mapped by
          -- other plugins before putting this into your config
          local opts = {silent = true, noremap = true, expr = true, replace_keycodes = false}
          keyset("i", "<TAB>", 'coc#pum#visible() ? coc#pum#next(1) : v:lua.check_back_space() ? "<TAB>" : coc#refresh()', opts)
          keyset("i", "<S-TAB>", [[coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"]], opts)

          -- Make <CR> to accept selected completion item or notify coc.nvim to format
          -- <C-g>u breaks current undo, please make your own choice
          keyset("i", "<cr>", [[coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"]], opts)

          -- Use <c-j> to trigger snippets
          keyset("i", "<c-j>", "<Plug>(coc-snippets-expand-jump)")
          -- Use <c-space> to trigger completion
          keyset("i", "<c-space>", "coc#refresh()", {silent = true, expr = true})

          -- Use `[g` and `]g` to navigate diagnostics
          -- Use `:CocDiagnostics` to get all diagnostics of current buffer in location list
          keyset("n", "[g", "<Plug>(coc-diagnostic-prev)", {silent = true})
          keyset("n", "]g", "<Plug>(coc-diagnostic-next)", {silent = true})

          -- GoTo code navigation
          keyset("n", "gd", "<Plug>(coc-definition)", {silent = true})
          keyset("n", "gy", "<Plug>(coc-type-definition)", {silent = true})
          keyset("n", "gi", "<Plug>(coc-implementation)", {silent = true})
          keyset("n", "gr", "<Plug>(coc-references)", {silent = true})

          -- Use K to show documentation in preview window
          function _G.show_docs()
              local cw = vim.fn.expand('<cword>')
              if vim.fn.index({'vim', 'help'}, vim.bo.filetype) >= 0 then
                  vim.api.nvim_command('h ' .. cw)
              elseif vim.api.nvim_eval('coc#rpc#ready()') then
                  vim.fn.CocActionAsync('doHover')
              else
                  vim.api.nvim_command('!' .. vim.o.keywordprg .. ' ' .. cw)
              end
          end
          keyset("n", "K", '<CMD>lua _G.show_docs()<CR>', {silent = true})

          -- Highlight the symbol and its references on a CursorHold event(cursor is idle)
          vim.api.nvim_create_augroup("CocGroup", {})
          vim.api.nvim_create_autocmd("CursorHold", {
              group = "CocGroup",
              command = "silent call CocActionAsync('highlight')",
              desc = "Highlight symbol under cursor on CursorHold"
          })

          -- Symbol renaming
          keyset("n", "<leader>rn", "<Plug>(coc-rename)", {silent = true})
        '';
      };

      xdg.configFile = {
        "efm-langserver/config.yaml".text = ''
          languages:
            markdown:
              lint-command: 'markdownlint -s'
              lint-stdin: true
              lint-formats:
                - '%f:%l %m'
                - '%f:%l:%c %m'
                - '%f: %l: %m'

            vim:
              lint-command: 'vint -'
              lint-stdin: true
        '';
      };
    }
  );
}
