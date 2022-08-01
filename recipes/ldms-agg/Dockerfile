# ovishpc/ldms-agg
#
# The docker context is prepared by './docker-build.sh'.

FROM ubuntu:22.04

SHELL [ "/bin/bash", "-c" ]

# Get LDMS dependencies
RUN export DEBIAN_FRONTEND=noninteractive ; \
    apt-get update -y ; \
    apt-get install -y librdmacm1 libibverbs1 libpapi6.0 libpfm4 munge \
                       python3 python3-numpy python3-pandas \
		       rpcbind curl \
                       ; \
    apt-get autoremove -y ; \
    apt-get clean -y ;

# copy LDMS binaries
ADD --chown=root:root bin /opt/ovis/bin/
ADD --chown=root:root sbin /opt/ovis/sbin/
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

RUN echo > /opt/ovis/sbin/ldmsd.sh -e "#!/bin/bash\n\
\n# Add '-x sock:411' to the CLI argument -x has not been specified.\n\
OPTS=\"\$*\"\n\
if [[ \" \$OPTS \" != *\\ -x\\ * ]]; then\n\
  OPTS=\"\${OPTS} -x sock:411\"\n\
fi\n\
CMD=\"ldmsd -F \${OPTS}\"\n\
echo \"Executing command: \${CMD}\"\n\
exec \${CMD}\n\
\n\
" ; \
chmod 755 /opt/ovis/sbin/ldmsd.sh ;

ENTRYPOINT [ "ldmsd.sh" ]
