# ovishpc/ldms-dev

FROM ubuntu:22.04

SHELL [ "/bin/bash", "-c" ]

# Informative prompt
RUN /bin/echo >/etc/profile.d/prompt.sh -e "\
myprompt() {\n\
	if test -z \"\$parent\"; then\n\
		if ((PPID)); then\n\
			parent=\$(ps -o cmd --no-headers \$PPID | awk '{ print \$1 }')\n\
		else\n\
			parent=\"--\"\n\
		fi\n\
	fi\n\
	if test -z \"\$left\"; then\n\
		if (( \$UID )); then\n\
			# This is regular user\n\
			left='\${debian_chroot:+(\$debian_chroot)}\[\\\\033[01;32m\]\u\[\\\\033[01;33m\]@\h\[\\\\033[01;34m\] \w'\n\
		else\n\
			# This is root\n\
			left='\${debian_chroot:+(\$debian_chroot)}\[\\\\033[01;31m\]\u\[\\\\033[01;33m\]@\h\[\\\\033[01;34m\] \w'\n\
		fi\n\
	fi\n\
\n\
	_branch=\"\$(git symbolic-ref HEAD --short 2>/dev/null || echo '--')\"\n\
	_git_sym_ref=\"\\\\033[0;32m(git-branch: \$_branch)\"\n\
\n\
	right=\"\\\\[\\\\033[01;31m\\\\][\$parent]\"\n\
	[[ \"\$TERM\" = \"linux\" ]] || echo -ne \"\\\\033]0;\${USER}@\${HOSTNAME}:\$PWD\\\\007\"\n\
	PS1=\$(printf \"\\\\n%s %s\\\\n%s\\\\n\\\\[\\\\033[01;34m\\\\]\\\\$\\\\[\\\\033[00m\\\\] \" \"\$right\" \"\$_git_sym_ref\" \"\$left\" )\n\
}\n\
export -f myprompt\n\
export PROMPT_COMMAND=myprompt\n\
"

# Rich color for `less` pager
RUN /bin/echo >/etc/profile.d/less_color.sh -e "\
export LESS_TERMCAP_mb=\$'\\\\E[01;31m'       # begin blinking\n\
export LESS_TERMCAP_md=\$'\\\\E[01;38;5;74m'  # begin bold\n\
export LESS_TERMCAP_me=\$'\\\\E[0m'           # end mode\n\
export LESS_TERMCAP_se=\$'\\\\E[0m'           # end standout-mode\n\
export LESS_TERMCAP_so=\$'\\\\E[38;5;016m\\\\E[48;5;220m'    # begin standout-mode - info box\n\
export LESS_TERMCAP_ue=\$'\\\\E[0m'           # end underline\n\
export LESS_TERMCAP_us=\$'\\\\E[04;38;5;146m' # begin underline\n\
"

# gitconfig with convenient aliases (e.g. `git ln`)
RUN /bin/echo > /etc/gitconfig -e "\
[core]\n\
editor = vim\n\
pager = less -S -R\n\
\n\
[color]\n\
ui = True\n\
\n\
[log]\n\
decorate = True\n\
\n\
[alias]\n\
ln = log --graph --pretty=format:'%C(auto)%h %d %s %C(ul white)-%an'\n\
ln2 = log --graph --pretty=format:'%C(auto)%H%d%n%ad (%ar)%n%s%n%C(ul white)-%an%n'\n\
pick = cherry-pick\n\
shows = show --stat -p\n\
ffmerge = merge --ff-only\n\
\n\
[diff]\n\
tool = vimdiff\n\
wsErrorHighlight = all\n\
\n\
[push]\n\
default = simple\n\
"

# vimrc
RUN mkdir -p /etc/vim/
RUN /bin/echo > /etc/vim/vimrc.local -e "\
\" /etc/vim/vimrc.local\n\
\"\n\
\n\
if filereadable(\"/etc/vim/vimrc.vundle\")\n\
  source /etc/vim/vimrc.vundle\n\
endif\n\
\n\
set encoding=utf-8\n\
set fileencoding=utf-8\n\
\n\
\" explicitly source defaults.vim first. Otherwise, if there is no ~/.vimrc,\n\
\" defaults.vim get sourced after global vimrc file.\n\
source \$VIMRUNTIME/defaults.vim\n\
let skip_defaults_vim = 1\n\
\n\
\" filetype plugin indent on\n\
filetype plugin on\n\
set ai\n\
set formatoptions+=ro\n\
\n\
set hlsearch\n\
nnoremap  :noh<CR>\n\
\n\
set laststatus=2\n\
set noexpandtab\n\
\n\
autocmd BufEnter * :syntax sync fromstart\n\
\n\
let g:load_doxygen_syntax=1\n\
\n\
function EliminateTrailingSpaces()\n\
	norm m'\n\
	%s/\\s\\+\$//e\n\
	norm \`'\n\
endfunction\n\
autocmd! BufWritePre * :call EliminateTrailingSpaces()\n\
\n\
set t_Co=16\n\
\n\
\" Line wrap settings\n\
set textwidth=80\n\
set colorcolumn=+1\n\
highlight ColorColumn ctermbg=7\n\
\n\
\" parentheses highlight\n\
highlight MatchParen cterm=bold ctermbg=none ctermfg=none\n\
\n\
set number\n\
\n\
set nocompatible\n\
set completeopt=longest,menu,preview,menuone\n\
\n\
let g:SuperTabNoCompleteAfter = ['\w', '\s', '^', '.']\n\
\n\
highlight Search cterm=NONE ctermfg=0 ctermbg=11 guibg=Yellow guifg=Black\n\
highlight Visual cterm=NONE ctermfg=0 ctermbg=6 guibg=Yellow guifg=Black\n\
\n\
\" Easier vimdiff color for dark bg\n\
hi DiffAdd cterm=bold ctermbg=4\n\
hi DiffChange cterm=bold ctermbg=5\n\
hi DiffDelete cterm=bold ctermfg=0 ctermbg=6\n\
hi DiffText cterm=bold ctermbg=1\n\
\n\
\" Fold highlight for dark background\n\
hi Folded cterm=bold ctermfg=0 ctermbg=7\n\
hi FoldColumn cterm=bold ctermfg=0 ctermbg=7\n\
\n\
set comments+=fb:\[\ \]\n\
set comments+=fb:\[*\]\n\
\n\
\" Airline options\n\
let g:airline#extensions#tabline#enabled = 0\n\
let g:airline#extensions#tabline#show_buffers = 0\n\
let g:airline_powerline_fonts = 1\n\
let g:airline_theme=\"wombat\"\n\
let g:airline#extensions#tabline#left_sep = ''\n\
let g:airline#extensions#tabline#left_alt_sep = ''\n\
let g:airline#extensions#tabline#right_sep = ''\n\
let g:airline#extensions#tabline#right_alt_sep = ''\n\
let g:airline#extensions#whitespace#mixed_indent_algo = 1\n\
let g:airline#extensions#whitespace#checks = [ 'indent', 'trailing', 'long' ]\n\
let g:airline#extensions#branch#enabled = 1\n\
let g:airline#extensions#branch#displayed_head_limit = 10\n\
\n\
\" youcompleteme options\n\
let g:ycm_auto_trigger = 0\n\
highlight YcmErrorSection ctermfg=White ctermbg=Red\n\
highlight YcmWarningSection ctermfg=Black ctermbg=Blue\n\
let g:ycm_global_ycm_extra_conf = '/etc/vim/ycm_extra_conf.py'\n\
\n\
function ModifyGdYcm()\n\
	map gd :YcmCompleter GoToDefinitionElseDeclaration<CR>\n\
endfunction\n\
\n\
autocmd FileType c :call ModifyGdYcm()\n\
\n\
function MyTabLabel(n)\n\
  let buflist = tabpagebuflist(a:n)\n\
  let winnr = tabpagewinnr(a:n)\n\
  let fullname = bufname(buflist[winnr - 1])\n\
  let tmp = split(fullname, \"/\")\n\
  let lenn = len(tmp)\n\
  if lenn > 0\n\
    let s = (a:n).':'.tmp[lenn-1]\n\
  else\n\
    let s = (a:n)\n\
  endif\n\
  return s\n\
endfunction\n\
\n\
function MyTabLine()\n\
  let s = ''\n\
  for i in range(tabpagenr('\$'))\n\
    \" select the highlighting\n\
    if i + 1 == tabpagenr()\n\
      let s .= '%#TabLineSel#'\n\
    else\n\
      let s .= '%#TabLine#'\n\
    endif\n\
\n\
    \" set the tab page number (for mouse clicks)\n\
    let s .= '%' . (i + 1) . 'T'\n\
\n\
    \" the label is made by MyTabLabel()\n\
    let s .= ' %{MyTabLabel(' . (i + 1) . ')} '\n\
  endfor\n\
\n\
  \" after the last tab fill with TabLineFill and reset tab page nr\n\
  let s .= '%#TabLineFill#%T'\n\
\n\
  \" right-align the label to close the current tab page\n\
  if tabpagenr('\$') > 1\n\
    let s .= '%=%#TabLine#%999Xclose'\n\
  endif\n\
\n\
  return s\n\
endfunction\n\
\n\
set tabline=%!MyTabLine()\n\
runtime ftplugin/man.vim\n\
nnoremap K :Man <cword><CR>\n\
\n\
\" cscope key map\n\
nmap <C-\>s :cs find s <C-R>=expand(\"<cword>\")<CR><CR>\n\
nmap <C-\>g :cs find g <C-R>=expand(\"<cword>\")<CR><CR>\n\
nmap <C-\>c :cs find c <C-R>=expand(\"<cword>\")<CR><CR>\n\
nmap <C-\>t :cs find t <C-R>=expand(\"<cword>\")<CR><CR>\n\
nmap <C-\>e :cs find e <C-R>=expand(\"<cword>\")<CR><CR>\n\
nmap <C-\>f :cs find f <C-R>=expand(\"<cfile>\")<CR><CR>\n\
nmap <C-\>i :cs find i ^<C-R>=expand(\"<cfile>\")<CR>\$<CR>\n\
nmap <C-\>d :cs find d <C-R>=expand(\"<cword>\")<CR><CR>\n\
\n\
\" netrw - the usual plugin used to browse files\n\
\" tree style listing\n\
let g:netrw_liststyle = 3\n\
\n\
\" disable modeline\n\
set modelines=0\n\
set nomodeline\n\
\n\
\" time before becoming idle\n\
set updatetime=500\n\
\n\
\" Tagbar\n\
let g:tagbar_sort = 0\n\
hi TagbarHighlight cterm=bold,reverse\n\
\n\
let g:tagbar_type_markdown = {\n\
    \ 'ctagstype': 'markdown',\n\
    \ 'ctagsbin' : '/opt/markdown2ctags.py',\n\
    \ 'ctagsargs' : '-f - --sort=yes --sro=»',\n\
    \ 'kinds' : [\n\
        \ 's:sections',\n\
        \ 'i:images'\n\
    \ ],\n\
    \ 'sro' : '»',\n\
    \ 'kind2scope' : {\n\
        \ 's' : 'section',\n\
    \ },\n\
    \ 'sort': 0,\n\
\ }\n\
\n\
\" Man -- the manpage display\n\
\" open new tab instead of splitting window\n\
let g:ft_man_open_mode = 'tab'\n\
\n\
set incsearch\n\
\n\
\" ctrlp\n\
let g:ctrlp_prompt_mappings = {\n\
  \ 'AcceptSelection(\"e\")': ['<2-LeftMouse>'],\n\
  \ 'AcceptSelection(\"t\")': ['<c-t>', '<cr>'],\n\
  \}\n\
\n\
command Mann execute \"Man \" . expand(\"%:p\")\n\
\n\
\" disable mouse click\n\
set mouse-=a\n\
\n\
set showcmd\n\
\n\
\" Allow \${PWD}/.vimrc (useful for per-project vim setting)\n\
set exrc\n\
"

# packages
RUN /bin/bash -c ' \
export DEBIAN_FRONTEND=noninteractive ; \
apt-get update -y ; \
yes | unminimize ; \
apt-get install -y man-db git build-essential python3-dev python3-pip etcd \
	openssl libssl-dev libssl-doc libibverbs-dev uuid-dev sudo tmux \
	curl libcurl4-openssl-dev \
	vim vim-fugitive vim-airline-themes vim-airline \
	vim-youcompleteme vim-scripts vim-ctrlp \
	papi-tools libpapi-dev libpfm4-dev \
	bash-completion \
	autoconf automake gnu-standards libtool gettext \
	flex bison libkrb5-dev libreadline-dev \
	python3-numpy python3-pandas cython3 pkg-config \
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
	python3-flask python3-gevent \
	; \
ln -s /usr/bin/cython3 /usr/bin/cython ; \
apt-get autoremove -y; \
apt-get autoclean -y; \
apt-get clean -y; \
'

RUN pip3 install protobuf==3.20 etcd3

RUN /bin/bash -c ' \
pushd /opt/ ;\
curl -LO https://archive.apache.org/dist/kafka/2.1.0/kafka_2.12-2.1.0.tgz ;\
tar xzf kafka_2.12-2.1.0.tgz ; \
mkdir kafka_2.12-2.1.0/logs/ ; \
'

RUN /bin/bash -c '\
mkdir -p /run/sshd ; \
'

RUN /bin/bash -c '\
cd /root ; \
yes "" | ssh-keygen ; \
cp .ssh/id_rsa.pub .ssh/authorized_keys ; \
chmod 600 .ssh/authorized_keys ; \
'

RUN /bin/bash -c '\
set -e ;\
cd /root ;\
git clone https://github.com/confluentinc/libserdes -b v7.3.2 ;\
cd libserdes ;\
./configure ;\
make ;\
make install ;\
'

RUN pip3 install confluent_kafka==2.3.0 fastavro==1.9.2

RUN /usr/sbin/ldconfig
