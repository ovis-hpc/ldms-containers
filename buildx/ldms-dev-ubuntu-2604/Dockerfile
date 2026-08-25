# ovishpc/ldms-dev-ubuntu-2404

FROM ubuntu:26.04

SHELL [ "/bin/bash", "-c" ]


# packages
RUN <<EOF
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install unminimize
yes | unminimize
apt-get autoremove -y
apt-get autoclean -y
apt-get clean -y
EOF

RUN <<EOF
apt-get update -y
apt-get install -y man-db git build-essential python3-dev python3-pip \
	openssl libssl-dev libssl-doc libibverbs-dev uuid-dev sudo tmux \
	curl libcurl4-openssl-dev \
	vim vim-fugitive vim-airline-themes vim-airline \
	vim-addon-manager \
	vim-youcompleteme vim-scripts vim-ctrlp \
	papi-tools libpapi-dev libpfm4-dev \
	bash-completion \
	autoconf automake gnu-standards libtool gettext \
	flex bison libkrb5-dev libreadline-dev \
	python3-numpy python3-pandas pkg-config \
	libmunge-dev libslurm-dev \
	slurmd slurmctld \
	exuberant-ctags \
	librdmacm-dev \
	gdb dnsutils iproute2 inetutils-ping \
	npm \
	librdkafka-dev \
	openssh-server \
	openjdk-11-jdk \
	avro-bin libavro-dev python3-avro \
	libjansson-dev \
	python3-docutils \
	etcd-server \
	python3-etcd3 \
	python3-confluent-kafka \
	cython3
apt-get autoremove -y
apt-get autoclean -y
apt-get clean -y
EOF

RUN <<EOF
vam install -w ctrlp youcompleteme
EOF

RUN <<EOF
pushd /opt/
curl -LO https://archive.apache.org/dist/kafka/2.1.0/kafka_2.12-2.1.0.tgz
tar xzf kafka_2.12-2.1.0.tgz
mkdir kafka_2.12-2.1.0/logs/
EOF

RUN mkdir -p /run/sshd

RUN <<EOF
cd /root
mkdir .ssh
yes "" | ssh-keygen
cp .ssh/id_ed25519.pub .ssh/authorized_keys
chmod 600 .ssh/authorized_keys
EOF

RUN <<EOF
set -e
cd /root
git clone https://github.com/confluentinc/libserdes -b v8.3.1
cd libserdes
# Patch tinycthread.h - GNU23 stdlib already have call_once() and associates
sed -i 's/#define ONCE_FLAG.*//' src/tinycthread.h
sed -i 's/#define once_flag.*//' src/tinycthread.h
sed -i 's/#define call_once.*//' src/tinycthread.h
./configure
make
make install
EOF

# Informative prompt
COPY <<EOF /etc/profile.d/prompt.sh
myprompt() {
	if test -z "\$parent"; then
		if ((PPID)); then
			parent=`ps -o cmd --no-headers \$PPID | awk '{ print \$1 }'`
		else
			parent='--'
		fi
	fi
	if test -z "\$left"; then
		if (( \$UID )); then
			# This is regular user
			left='\${debian_chroot:+(\$debian_chroot)}\\[\\033[01;32m\\]\\u\\[\\033[01;33m\\]@\\h\\[\\033[01;34m\\] \\w'
		else
			# This is root
			left='\${debian_chroot:+(\$debian_chroot)}\\[\\033[01;31m\\]\\u\\[\\033[01;33m\\]@\\h\\[\\033[01;34m\\] \\w'
		fi
	fi

	_branch="\$(git symbolic-ref HEAD --short 2>/dev/null || echo '--')"
	_git_sym_ref="\\033[0;32m(git-branch: \$_branch)"

	right="\\[\\033[01;31m\\][\$parent]"
	[[ "\$TERM" = "linux" ]] || echo -ne "\\033]0;\${USER}@\${HOSTNAME}:\$PWD\\007"
	PS1=\$(printf "\\n%s %s\\n%s\\n\\[\\033[01;34m\\]\\$\\[\\033[00m\\] " "\$right" "\$_git_sym_ref" "\$left" )
}

export -f myprompt
export PROMPT_COMMAND=myprompt
EOF

# Rich color for `less` pager
COPY <<EOF /etc/profile.d/less_color.sh
export LESS_TERMCAP_mb=\$'\\E[01;31m'       # begin blinking
export LESS_TERMCAP_md=\$'\\E[01;38;5;74m'  # begin bold
export LESS_TERMCAP_me=\$'\\E[0m'           # end mode
export LESS_TERMCAP_se=\$'\\E[0m'           # end standout-mode
export LESS_TERMCAP_so=\$'\\E[38;5;016m\\E[48;5;220m'    # begin standout-mode - info box
export LESS_TERMCAP_ue=\$'\\E[0m'           # end underline
export LESS_TERMCAP_us=\$'\\E[04;38;5;146m' # begin underline
EOF

# gitconfig with convenient aliases (e.g. `git ln`)
COPY <<EOF /etc/gitconfig
[core]
editor = vim
pager = less -S -R

[color]
ui = True

[log]
decorate = True

[alias]
ln = log --graph --pretty=format:'%C(auto)%h %d %s %C(ul white)-%an'
ln2 = log --graph --pretty=format:'%C(auto)%H%d%n%ad (%ar)%n%s%n%C(ul white)-%an%n'
pick = cherry-pick
shows = show --stat -p
ffmerge = merge --ff-only

[diff]
tool = vimdiff
wsErrorHighlight = all

[push]
default = simple
EOF

# vimrc
RUN mkdir -p /etc/vim/
COPY <<EOF /etc/vim/vimrc.local
" /etc/vim/vimrc.local
"

if filereadable("/etc/vim/vimrc.vundle")
  source /etc/vim/vimrc.vundle
endif

set encoding=utf-8
set fileencoding=utf-8

" explicitly source defaults.vim first. Otherwise, if there is no ~/.vimrc,
" defaults.vim get sourced after global vimrc file.
source \$VIMRUNTIME/defaults.vim
let skip_defaults_vim = 1

" filetype plugin indent on
filetype plugin on
set ai
set formatoptions+=ro

set hlsearch
nnoremap  :noh<CR>

set laststatus=2
set noexpandtab

autocmd BufEnter * :syntax sync fromstart

let g:load_doxygen_syntax=1

function EliminateTrailingSpaces()
	norm m'
	%s/\\s\\+\$//e
	norm \`'
endfunction
autocmd! BufWritePre * :call EliminateTrailingSpaces()

set t_Co=16

" Line wrap settings
set textwidth=80
set colorcolumn=+1
highlight ColorColumn ctermbg=7

" parentheses highlight
highlight MatchParen cterm=bold ctermbg=none ctermfg=none

set number

set nocompatible
set completeopt=longest,menu,preview,menuone

let g:SuperTabNoCompleteAfter = ['\\w', '\\s', '^', '.']

highlight Search cterm=NONE ctermfg=0 ctermbg=11 guibg=Yellow guifg=Black
highlight Visual cterm=NONE ctermfg=0 ctermbg=6 guibg=Yellow guifg=Black

" Easier vimdiff color for dark bg
hi DiffAdd cterm=bold ctermbg=4
hi DiffChange cterm=bold ctermbg=5
hi DiffDelete cterm=bold ctermfg=0 ctermbg=6
hi DiffText cterm=bold ctermbg=1

" Fold highlight for dark background
hi Folded cterm=bold ctermfg=0 ctermbg=7
hi FoldColumn cterm=bold ctermfg=0 ctermbg=7

set comments+=fb:\\[\\ \\]
set comments+=fb:\\[*\\]

" Airline options
let g:airline#extensions#tabline#enabled = 0
let g:airline#extensions#tabline#show_buffers = 0
let g:airline_powerline_fonts = 1
let g:airline_theme="wombat"
let g:airline#extensions#tabline#left_sep = ''
let g:airline#extensions#tabline#left_alt_sep = ''
let g:airline#extensions#tabline#right_sep = ''
let g:airline#extensions#tabline#right_alt_sep = ''
let g:airline#extensions#whitespace#mixed_indent_algo = 1
let g:airline#extensions#whitespace#checks = [ 'indent', 'trailing', 'long' ]
let g:airline#extensions#branch#enabled = 1
let g:airline#extensions#branch#displayed_head_limit = 10

" youcompleteme options
let g:ycm_auto_trigger = 0
highlight YcmErrorSection ctermfg=White ctermbg=Red
highlight YcmWarningSection ctermfg=Black ctermbg=Blue
let g:ycm_global_ycm_extra_conf = '/etc/vim/ycm_extra_conf.py'

function ModifyGdYcm()
	map gd :YcmCompleter GoToDefinitionElseDeclaration<CR>
endfunction

autocmd FileType c :call ModifyGdYcm()

function MyTabLabel(n)
  let buflist = tabpagebuflist(a:n)
  let winnr = tabpagewinnr(a:n)
  let fullname = bufname(buflist[winnr - 1])
  let tmp = split(fullname, "/")
  let lenn = len(tmp)
  if lenn > 0
    let s = (a:n).':'.tmp[lenn-1]
  else
    let s = (a:n)
  endif
  return s
endfunction

function MyTabLine()
  let s = ''
  for i in range(tabpagenr('\$'))
    " select the highlighting
    if i + 1 == tabpagenr()
      let s .= '%#TabLineSel#'
    else
      let s .= '%#TabLine#'
    endif

    " set the tab page number (for mouse clicks)
    let s .= '%' . (i + 1) . 'T'

    " the label is made by MyTabLabel()
    let s .= ' %{MyTabLabel(' . (i + 1) . ')} '
  endfor

  " after the last tab fill with TabLineFill and reset tab page nr
  let s .= '%#TabLineFill#%T'

  " right-align the label to close the current tab page
  if tabpagenr('\$') > 1
    let s .= '%=%#TabLine#%999Xclose'
  endif

  return s
endfunction

set tabline=%!MyTabLine()
runtime ftplugin/man.vim
nnoremap K :Man <cword><CR>

" cscope key map
nmap <C-\\>s :cs find s <C-R>=expand("<cword>")<CR><CR>
nmap <C-\\>g :cs find g <C-R>=expand("<cword>")<CR><CR>
nmap <C-\\>c :cs find c <C-R>=expand("<cword>")<CR><CR>
nmap <C-\\>t :cs find t <C-R>=expand("<cword>")<CR><CR>
nmap <C-\\>e :cs find e <C-R>=expand("<cword>")<CR><CR>
nmap <C-\\>f :cs find f <C-R>=expand("<cfile>")<CR><CR>
nmap <C-\\>i :cs find i ^<C-R>=expand("<cfile>")<CR>\$<CR>
nmap <C-\\>d :cs find d <C-R>=expand("<cword>")<CR><CR>

" netrw - the usual plugin used to browse files
" tree style listing
let g:netrw_liststyle = 3

" disable modeline
set modelines=0
set nomodeline

" time before becoming idle
set updatetime=500

" Tagbar
let g:tagbar_sort = 0
hi TagbarHighlight cterm=bold,reverse

let g:tagbar_type_markdown = {
    \\ 'ctagstype': 'markdown',
    \\ 'ctagsbin' : '/opt/markdown2ctags.py',
    \\ 'ctagsargs' : '-f - --sort=yes --sro=»',
    \\ 'kinds' : [
        \\ 's:sections',
        \\ 'i:images'
    \\ ],
    \\ 'sro' : '»',
    \\ 'kind2scope' : {
        \\ 's' : 'section',
    \\ },
    \\ 'sort': 0,
\\ }

" Man -- the manpage display
" open new tab instead of splitting window
let g:ft_man_open_mode = 'tab'

set incsearch

" ctrlp
let g:ctrlp_prompt_mappings = {
  \\ 'AcceptSelection("e")': ['<2-LeftMouse>'],
  \\ 'AcceptSelection("t")': ['<c-t>', '<cr>'],
  \\}

command Mann execute "Man " . expand("%:p")

" disable mouse click
set mouse-=a

set showcmd

" Allow \${PWD}/.vimrc (useful for per-project vim setting)
set exrc
EOF

COPY <<EOF /etc/profile.d/lang.sh
export LANG=en_US.UTF-8
EOF

RUN /usr/sbin/ldconfig
