# ovishpc/ldms-maestro
#
# The docker context is prepared by './docker-build.sh'.

FROM ubuntu:22.04

SHELL [ "/bin/bash", "-c" ]

# Get LDMS dependencies
RUN export DEBIAN_FRONTEND=noninteractive ; \
    apt-get update -y ; \
    apt-get install -y librdmacm1 libibverbs1 libpapi6.0 libpfm4 munge ; \
    apt-get install -y python3 python3-pip python3-yaml etcd ; \
    apt-get autoremove -y ; \
    apt-get clean -y ;

RUN pip3 install protobuf==3.20 etcd3

# copy LDMS binaries
ADD --chown=root:root bin /opt/ovis/bin/
ADD --chown=root:root lib /opt/ovis/lib/
ADD --chown=root:root etc /opt/ovis/etc/

# setup LDMS env
RUN ln -s /opt/ovis/etc/profile.d/set-ovis-variables.sh /etc/profile.d/ ; \
    ln -s /opt/ovis/etc/ld.so.conf.d/ovis-ld-so.conf /etc/ld.so.conf.d/ ; \
    ldconfig ;
ENV PATH=/opt/ovis/bin:/opt/ovis/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV PYTHONPATH=/opt/ovis/lib/python3.10/site-packages:/opt/ovis/lib/python3.10/dist-packages
ENV LDMSD_PLUGIN_LIBPATH=/opt/ovis/lib/ovis-ldms
ENV ZAP_LIBPATH=/opt/ovis/lib/ovis-ldms

# Default /etc/etcd.yaml (empty) for etcd
RUN touch /etc/etcd.yaml

RUN echo > /etc/ldms_cfg.yaml -e "\
daemons:\n\
  - names : none\n\
    hosts : localhost\n\
    endpoints :\n\
      - names : none-ep\n\
        ports : 411\n\
        xprt : sock\n\
        maestro_comm : True\n\
        auth :\n\
          name : none\n\
          plugin : none\n\
"

# maestro `--cluster` config file
RUN echo > /etc/cluster.yaml -e "\
members:\n\
  - host: localhost\n\
    port: 2379\n\
"

RUN echo > /etcd-check.sh -e "#!/bin/bash\n\
etcdctl cluster-health && exit 0 || exit 1\n\
" ; \
chmod 755 /etcd-check.sh ;

RUN echo > /maestro-check.sh -e "#!/bin/bash\n\
pgrep -x maestro && exit 0 || exit 1\n\
" ; \
chmod 755 /maestro-check.sh

RUN echo > /health-check.sh -e "#!/bin/bash\n\
/etcd-check.sh && /maestro-check.sh && exit 0\n\
exit 1\n\
" ; \
chmod 755 /health-check.sh


RUN echo > /start.sh -e "#!/bin/bash\
\n# Start etcd, munged and then maestro daemon.\n\
set -e\n\
etcd --config-file /etc/etcd.yaml >/var/log/etcd.log 2>&1 &\n\
N=5\n\
while (( N )) ; do\n\
  if /etcd-check.sh ; then\n\
    CHECKED=1\n\
    break\n\
  fi\n\
  N=$((N-1))\n\
  (( ! N )) || sleep 1\n\
done\n\
(( CHECKED )) || { echo 'etcd health check failed' ; exit 1 ; }\n\
\n\
HOST_MUNGE=\$( mount | grep '\\/run\\/munge' 2>/dev/null || true ) \n\
if [[ -z \"\${HOST_MUNGE}\" ]] ; then\n\
  mkdir -p /var/run/munge\n\
  chown munge:munge /var/run/munge\n\
  su -s /bin/bash munge bash -c munged\n\
  sleep 1\n\
fi\n\
\n# check munge\n\
OUT=\$( echo abc | munge | unmunge | tail -n1 || true )\n\
if [[ \"\${OUT}\" == \"abc\" ]]; then\n\
  echo \"Munge check OK\"\n\
else\n\
  echo \"Munge check failed\"\n\
  exit -1\n\
fi\n\
\n\
maestro_ctrl --prefix maestro --cluster /etc/cluster.yaml --ldms_config /etc/ldms_cfg.yaml\n\
sleep 5\n\
maestro --prefix maestro --cluster /etc/cluster.yaml\n\
" ; \
chmod 755 /start.sh ;

RUN dd if=/dev/zero of=/etc/munge/munge.key bs=4096 count=1

HEALTHCHECK --interval=5s --start-period=10s CMD /health-check.sh || exit 1

ENTRYPOINT [ "/start.sh" ]
