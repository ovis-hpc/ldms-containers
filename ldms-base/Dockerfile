FROM centos:7

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

RUN /bin/bash -c '\
set -e ; \
set -x ; \
echo "---- Enable EPEL ----" ; \
yum install -y epel-release ; \
echo "---- yum install.. ----" ; \
yum install -y python3 openssh-server pssh sudo munge net-tools \
               iproute which ; \
echo "---- Generate sshd keys ----" ; \
yes "" | ssh-keygen ; \
cat /root/.ssh/id*.pub > /root/.ssh/authorized_keys ; \
pushd /etc/ssh ; \
yes "" | ssh-keygen -t rsa -f ssh_host_rsa_key ; \
yes "" | ssh-keygen -t ecdsa -f ssh_host_ecdsa_key ; \
yes "" | ssh-keygen -t ed25519 -f ssh_host_ed25519_key ; \
popd ; \
echo "---- Generate munge key ----" ; \
dd if=/dev/zero of=/etc/munge/munge.key bs=4096 count=1 \
    && chmod 600 /etc/munge/munge.key \
    && chown munge:munge /etc/munge/munge.key ; \
yum clean all ; \
'
