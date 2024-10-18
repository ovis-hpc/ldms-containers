# ldms-agg

# This is a named context defined by compose.yaml
FROM build
SHELL [ "/bin/bash", "-c" ]

FROM ubuntu:22.04
SHELL [ "/bin/bash", "-c" ]

# Get LDMS dependencies
RUN export DEBIAN_FRONTEND=noninteractive ; \
    apt-get update -y ; \
    apt-get install -y librdmacm1 libibverbs1 libpapi6.0 libpfm4 munge \
                       python3 python3-numpy python3-pandas \
		       rpcbind curl \
		       libjansson4 \
                       ; \
    apt-get autoremove -y ; \
    apt-get clean -y ;

# copy LDMS binaries
COPY --from=0 /opt/ovis/bin/ /opt/ovis/bin/
COPY --from=0 /opt/ovis/sbin/ /opt/ovis/sbin/
COPY --from=0 /opt/ovis/lib/ /opt/ovis/lib/
COPY --from=0 /opt/ovis/etc/ /opt/ovis/etc/

# setup LDMS env
RUN ln -s /opt/ovis/etc/profile.d/set-ovis-variables.sh /etc/profile.d/ ; \
    ln -s /opt/ovis/etc/ld.so.conf.d/ovis-ld-so.conf /etc/ld.so.conf.d/z-ovis.so.conf ; \
    ldconfig ;
ENV PATH=/opt/ovis/bin:/opt/ovis/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV PYTHONPATH=/opt/ovis/lib/python3.10/site-packages:/opt/ovis/lib/python3.10/dist-packages
ENV LDMSD_PLUGIN_LIBPATH=/opt/ovis/lib/ovis-ldms
ENV ZAP_LIBPATH=/opt/ovis/lib/ovis-ldms

RUN /bin/echo > /opt/ovis/sbin/ldmsd.sh -e "#!/bin/bash\n\
\n# Add '-x sock:411' to the CLI argument -x has not been specified.\n\
OPTS=\"\$*\"\n\
if [[ \" \${OPTS} \" == *\\ munge\\ * ]]; then\
\n   # Want munge\n\
  HOST_MUNGE=\$( mount | grep '\\/run\\/munge' 2>/dev/null ) \n\
  if [[ -z \"\${HOST_MUNGE}\" ]] ; then\n\
    mkdir -p /var/run/munge\n\
    chown munge:munge /var/run/munge\n\
    su -s /bin/bash munge bash -c munged\n\
    sleep 1\n\
  fi\n\
\n  # check munge\n\
  OUT=\$( echo abc | munge | unmunge | tail -n1 )\n\
  if [[ \"\${OUT}\" == \"abc\" ]]; then\n\
    echo \"Munge check OK\"\n\
  else\n\
    echo \"Munge check failed\"\n\
    exit -1\n\
  fi\n\
fi\n\
CMD=\"ldmsd \${OPTS}\"\n\
echo \"Executing command: \${CMD}\"\n\
exec \${CMD}\n\
\n\
" ; \
chmod 755 /opt/ovis/sbin/ldmsd.sh ;

RUN dd if=/dev/zero of=/etc/munge/munge.key bs=4096 count=1

ENTRYPOINT [ "ldmsd.sh" ]
