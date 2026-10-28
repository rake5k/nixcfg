# Neovim Keybinds Cheatsheet

Generated from config: `home/users/christian/vim/default.nix`,
`home/users/christian/vim/coc/default.nix`

`<leader>` is the Neovim default `\` (`mapleader` is not set). `vi`, `vim` and `vimdiff` all launch
Neovim.

## Git (gitsigns)

Active in buffers tracked by Git.

| Keybinding   | Action                                          |
| ------------ | ----------------------------------------------- |
| `]c`         | Next Hunk (native next change in diff mode)     |
| `[c`         | Previous Hunk (native prev change in diff mode) |
| `<leader>hs` | Stage Hunk                                      |
| `<leader>hr` | Reset Hunk                                      |
| `<leader>hp` | Preview Hunk                                    |
| `<leader>hb` | Blame Line (full commit message)                |
| `<leader>hd` | Diff Against Index                              |

## Git (lazygit)

| Keybinding   | Action                         |
| ------------ | ------------------------------ |
| `<leader>gg` | Open Lazygit (floating window) |

## Completion (coc)

| Keybinding   | Mode   | Action                                    |
| ------------ | ------ | ----------------------------------------- |
| `Tab`        | Insert | Next Completion Item / Trigger Completion |
| `Shift+Tab`  | Insert | Previous Completion Item                  |
| `Enter`      | Insert | Accept Completion Item                    |
| `Ctrl+Space` | Insert | Trigger Completion                        |
| `Ctrl+J`     | Insert | Expand Snippet / Jump to Next Placeholder |

## Code Navigation (coc)

| Keybinding   | Action                                    |
| ------------ | ----------------------------------------- |
| `gd`         | Go to Definition                          |
| `gy`         | Go to Type Definition                     |
| `gi`         | Go to Implementation                      |
| `gr`         | Show References                           |
| `K`          | Show Documentation (`:help` in vim files) |
| `]g`         | Next Diagnostic                           |
| `[g`         | Previous Diagnostic                       |
| `<leader>rn` | Rename Symbol                             |

`:CocDiagnostics` lists all diagnostics of the current buffer in the location list. Files are
formatted on save.

## Surround (nvim-surround defaults)

| Keybinding         | Action                      | Example                         |
| ------------------ | --------------------------- | ------------------------------- |
| `ys{motion}{char}` | Surround Motion             | `ysiw)`: `foo` → `(foo)`        |
| `yss{char}`        | Surround Line               | `yss"`: `foo bar` → `"foo bar"` |
| `S{char}`          | Surround Selection (Visual) |                                 |
| `ds{char}`         | Delete Surrounding          | `ds"`: `"foo"` → `foo`          |
| `cs{old}{new}`     | Change Surrounding          | `cs'"`: `'foo'` → `"foo"`       |

An opening bracket (`(`, `[`, `{`) adds inner spaces, a closing one (`)`, `]`, `}`) does not.
`move_cursor = 'sticky'` keeps the cursor on its character as the surrounding text changes.

## Folding

`foldmethod` is `marker`: `{{{` / `}}}` comments delimit folds.

| Keybinding | Action          |
| ---------- | --------------- |
| `za`       | Toggle Fold     |
| `zR`       | Open All Folds  |
| `zM`       | Close All Folds |

See `:help nvim-surround.txt`, `:help gitsigns` and `:help coc-nvim.txt` for the full plugin
references.
