set clipboard=unnamedplus

"
" SPELL CHECK
"

filetype plugin on

set spellfile=~/.local/share/nvim/site/spell/shared.utf-8.add,~/.local/share/nvim/site/spell/de.utf-8.add,~/.local/share/nvim/site/spell/en.utf-8.add
autocmd FileType gitcommit setlocal spell spelllang=en_gb
autocmd FileType text setlocal spell spelllang=de_ch,en_gb

"
" THESAURI
"

set thesaurus+=~/.local/share/nvim/site/dict/openthesaurus.txt
set thesaurus+=~/.local/share/nvim/site/dict/mthesaur.txt

