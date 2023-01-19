function! myspacevim#before() abort
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


  "
  " VIMWIKI
  "
  set nocompatible

  let g:vimwiki_global_ext = 0
  syntax on

  let nextcloud_notes = {}
  let nextcloud_notes.path = '~/Nextcloud/Notes/'
  let nextcloud_notes.syntax = 'markdown'
  let nextcloud_notes.ext = 'md'
  let nextcloud_notes.list_margin = 0
  let g:vimwiki_list = [nextcloud_notes]
  let g:vimwiki_dir_link = 'index'

  autocmd FileType vimwiki setlocal spell spelllang=de_ch,en_gb

  function! VimwikiFindIncompleteTasks()
    lvimgrep /- \[ \]/ %:p
    lopen
  endfunction

  function! VimwikiFindAllIncompleteTasks()
    VimwikiSearch /- \[ \]/
    lopen
  endfunction

  :autocmd FileType vimwiki map wa :call VimwikiFindAllIncompleteTasks()<CR>
  :autocmd FileType vimwiki map wx :call VimwikiFindIncompleteTasks()<CR>

  autocmd BufNewFile ~/Nextcloud/Notes/diary/*.md
    \ call append(0,[
    \ "# " . split(expand('%:r'),'/')[-1], "",
    \ "## Todo",  "",
    \ "## Notes", "" ])

  function! ToggleCalendar()
    execute ":Calendar"
    if exists("g:calendar_open")
      if g:calendar_open == 1
        execute "q"
        unlet g:calendar_open
      else
        g:calendar_open = 1
      end
    else
      let g:calendar_open = 1
    end
  endfunction
  :autocmd FileType vimwiki map ,c :call ToggleCalendar()<CR>
endfunction

function! myspacevim#after() abort
"  lua << EOF
"  local opt = requires('spacevim.opt')
"  opt.enable_projects_cache = false
"  opt.enable_statusline_mode = true
"EOF
endfunction

