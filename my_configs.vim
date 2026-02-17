set rnu
set nu

"colorscheme slate
colorscheme desert

let &t_SI = "\e[6 q"
let &t_EI = "\e[2 q"

function! ClipboardYank(type, ...)
  let sel_save = &selection
  let &selection = "inclusive"
  let reg_save = @@

  if a:0  " Invoked from Visual mode
    silent exe "normal! gvy"
  elseif a:type == 'line'
    silent exe "normal! '[V']y"
  elseif a:type == 'block'
    silent exe "normal! `[\<C-V>`]y"
  else
    silent exe "normal! `[v`]y"
  endif

  call system('xclip -selection clipboard', @@)

  let &selection = sel_save
  let @@ = reg_save
endfunction

nnoremap <silent> <Leader>y :<C-u>set opfunc=ClipboardYank<CR>g@

function! ClipboardYankLines(count)
  let reg_save = @@
  
  if a:count > 1
    silent exe "normal! " . a:count . "yy"
  else
    silent exe "normal! yy"
  endif
  
  call system('xclip -selection clipboard', @@)
  
  let @@ = reg_save
endfunction

nnoremap <silent> <Leader>yy :<C-u>call ClipboardYankLines(v:count1)<CR>

nnoremap <Leader>pp :r !xclip -o -selection clipboard<CR>
inoremap <Leader>pp <Esc>:set paste<CR>i<C-r>=system('xclip -o -selection clipboard')<CR><Esc>:set nopaste<CR>i
inoremap <leader>c [CODE]<CR><CR>[/CODE]<Up>

