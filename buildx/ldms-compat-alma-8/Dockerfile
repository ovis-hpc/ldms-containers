# ovishpc/ldms-compat-alma-8

# This is a named context defined by compose.yaml
# (currently referring to ldms-dev-alma-8 target
FROM build

SHELL [ "/bin/bash", "-c" ]

RUN \
  cd ~ ; \
  git clone https://github.com/ovis-hpc/ldms -b OVIS-4.3.11 ldms-4.3.11 ; \
  for V in 4.3.{3..10}; do \
    git clone ldms-4.3.11 -b OVIS-${V} ldms-${V} ; \
  done

RUN \
  set -e ;\
  set -x ;\
  cd ~ ;\
  for V in 4.3.{3..11}; do \
    pushd ldms-${V} ;\
    ./autogen.sh ;\
    popd ;\
  done

# sos
RUN \
  set -e ;\
  set -x ;\
  cd ~ ;\
  git clone https://github.com/ovis-hpc/sos ;\
  cd sos; \
  ./autogen.sh ;\
  mkdir build ;\
  cd build ;\
  ../configure --prefix=/opt/sos ;\
  make ;\
  make install ;

RUN /bin/echo > /root/configure.sh -e "#!/bin/bash\n\
DNAME=\$(dirname \$0)\n\
CONFIGURE=\${DNAME}/configure\n\
PREFIX=\${PREFIX:-/opt/ovis}\n\
\n\
_DEBUGS_=(\n\
        -DDEBUG\n\
        -DEP_DEBUG\n\
        -DCTXT_DEBUG\n\
        -DPUSH_DEBUG\n\
        -DLOADAVG_CONFIG_DEBUG\n\
        -DLOADAVG_TYPE_DEBUG\n\
        -DSEND_RECV_DEBUG\n\
        -DZAP_DEBUG\n\
        -DDEBUG_ZAP_SOCK\n\
        -DTMP_DEBUG\n\
        -DZAP_UGNI_DEBUG\n\
)\n\
\n\
CFLAGS=\"-ggdb3 -O0\"\n\
\n\
_OPTIONS_=(\n\
        --prefix=\${PREFIX}\n\
\n\
        --enable-etc\n\
\n\
        # tests\n\
        --enable-zaptest\n\
        --enable-ldms-test\n\
        --enable-test_sampler\n\
\n\
        # xprt\n\
        --enable-fabric\n\
        --enable-rdma\n\
        --with-libfabric=/usr\n\
\n\
        # auth\n\
        --enable-munge\n\
\n\
        # stores\n\
        --enable-sos\n\
        --with-sos=/opt/sos\n\
        --enable-store-app\n\
\n\
        # samplers\n\
        --enable-tutorial-sampler\n\
        --enable-tutorial-store\n\
        --enable-app-sampler\n\
        --enable-slurm-sampler\n\
        --enable-spank-plugin\n\
        --enable-papi-sampler\n\
        --enable-syspapi-sampler\n\
)\n\
\n\
\${CONFIGURE} \${_OPTIONS_[*]} CFLAGS=\"\${CFLAGS}\"\n\
\n\
exit \$?\n\
"

RUN \
  set -e; \
  set -x; \
  cd ~ ;\
  for V in 4.3.{3..11}; do \
    pushd ldms-${V} ;\
    cp ../configure.sh ./ ;\
    chmod 755 configure.sh ;\
    sed -i "s|^PREFIX=.*|PREFIX=/opt/ovis-${V}|" configure.sh ;\
    popd ;\
  done

RUN \
  set -e; \
  set -x; \
  cd ~ ;\
  for V in 4.3.{3..11}; do \
    mkdir -p ldms-${V}/build ;\
    pushd ldms-${V}/build ;\
    ../configure.sh ;\
    make ;\
    make install ;\
    popd ;\
  done

# soft links
RUN \
  set -e; \
  set -x; \
  cd ~ ;\
  for V in 4.3.{3..11}; do \
    pushd /opt/ovis-${V}/sbin ;\
    ln -s ldmsd ldmsd-${V} ;\
    popd ;\
  done

# ldmsd script
RUN echo > /usr/local/sbin/ldmsd.sh -e "#!/bin/bash\n\
NAME=\$(basename \$0)\n\
NAME=\${NAME%.sh}\n\
V=\${NAME#ldmsd-}\n\
if [[ \"\${NAME}\" == \"ldmsd\" ]]; then\n\
        echo \"This is a template script and must not be called directly.\"\n\
        exit -1\n\
fi\n\
\n\
source /opt/ovis-\${V}/etc/profile.d/set-ovis-variables.sh\n\
ldmsd-\${V} \$@\n\
"
RUN chmod 755 /usr/local/sbin/ldmsd.sh

# ldms_ls script
RUN echo > /usr/local/sbin/ldms_ls.sh -e "#!/bin/bash\n\
NAME=\$(basename \$0)\n\
NAME=\${NAME%.sh}\n\
V=\${NAME#ldms_ls-}\n\
if [[ \"\${NAME}\" == \"ldms_ls\" ]]; then\n\
        echo \"This is a template script and must not be called directly.\"\n\
        exit -1\n\
fi\n\
\n\
source /opt/ovis-\${V}/etc/profile.d/set-ovis-variables.sh\n\
ldms_ls \$@\n\
"
RUN chmod 755 /usr/local/sbin/ldms_ls.sh

RUN \
  set -e; \
  set -x; \
  cd /usr/local/sbin ;\
  for V in 4 4.3.{3..11}; do \
    ln -s ldmsd.sh ldmsd-${V}.sh ;\
    ln -s ldms_ls.sh ldms_ls-${V}.sh ;\
  done

# munge
RUN \
  python3 -c "print('0'*1024)" > /etc/munge/munge.key ;\
  chown munge:munge /etc/munge/munge.key ;\
  chmod 600 /etc/munge/munge.key ;
