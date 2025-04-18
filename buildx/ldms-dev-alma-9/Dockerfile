# ovishpc/ldms-dev-alma-9

FROM almalinux:9

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

RUN /bin/echo >/etc/profile.d/ls_color.sh -e "\
alias ls='ls --color'\n\
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

# Enable "PowerTools" software repository
RUN /bin/bash -c 'sed -i "s|enabled=0|enabled=1|" /etc/yum.repos.d/*-crb.repo'

# Add Confluent repository
RUN /bin/bash -c 'rpm --import https://packages.confluent.io/rpm/7.9/archive.key'

RUN /bin/echo >/etc/yum.repos.d/confluent.repo -e "\
[Confluent]\n\
name=Confluent repository\n\
baseurl=https://packages.confluent.io/rpm/7.9\n\
gpgcheck=1\n\
gpgkey=https://packages.confluent.io/rpm/7.9/archive.key\n\
enabled=1\n\
\n\
[Confluent-Clients]\n\
name=Confluent Clients repository\n\
baseurl=https://packages.confluent.io/clients/rpm/centos/\$releasever/\$basearch\n\
gpgcheck=1\n\
gpgkey=https://packages.confluent.io/clients/rpm/archive.key\n\
enabled=1\n\
"

# Enable man pages. Need to reinstall the existing packages.
RUN /bin/bash -c ' \
dnf install -y man-db ; \
dnf reinstall -y $( rpm -qa ) ; \
'

# EPEL
RUN /bin/bash -c ' \
dnf install -y epel-release ; \
'

# Development tools
RUN /bin/bash -c ' \
dnf group install -y "Development Tools" ; \
'

# other packages
RUN /bin/bash -c ' \
dnf install -y --allowerasing \
	man-db python3-devel sudo tmux curl libcurl-devel \
	vim vim-powerline vim-fugitive \
	git python3-pip \
	openssl openssl-devel \
	libibverbs \
	libibverbs-devel \
	libuuid-devel \
	papi papi-devel \
	libpfm-devel \
	readline-devel \
	krb5-devel \
	python3-numpy \
	python3-Cython \
	python3-docutils \
	slurm-devel munge-libs munge-devel \
	slurm-slurmctld slurm-slurmd \
	ctags \
	librdmacm \
	bind-utils \
	iproute \
	npm \
	librdkafka-devel \
	openssh-server \
	jansson-devel \
	cmake \
	rpcgen \
	libfabric-devel \
	; \
'

# libavro
RUN /bin/bash -c '\
set -e ; \
cd /root ; \
git clone https://github.com/apache/avro -b branch-1.12 ; \
cd avro/lang/c ; \
mkdir -p build ; \
cd build ; \
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_BUILD_TYPE=Debug ; \
make ; \
make test ; \
make install ; \
'

# libserdes
RUN /bin/bash -c '\
set -e ;\
cd /root ;\
git clone https://github.com/confluentinc/libserdes -b v7.3.2 ;\
cd libserdes ;\
./configure ;\
make ;\
make install ;\
'

# ssh daemon
RUN /bin/bash -c '\
mkdir -p /run/sshd ; \
'

RUN /bin/bash -c '\
cd /root ; \
yes "" | ssh-keygen ; \
cp .ssh/id_rsa.pub .ssh/authorized_keys ; \
chmod 600 .ssh/authorized_keys ; \
'
