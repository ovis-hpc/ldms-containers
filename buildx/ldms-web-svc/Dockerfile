# ldms-ui

FROM build

FROM ubuntu:22.04

SHELL [ "/bin/bash", "-c" ]

# Get LDMS dependencies
RUN export DEBIAN_FRONTEND=noninteractive ; \
    apt-get update -y ; \
    apt-get install -y librdmacm1 libibverbs1 libpapi6.0 libpfm4 munge \
                       python3 python3-numpy python3-pandas \
		       uwsgi uwsgi-plugin-python3 \
		       python3-django python3-django-cors-headers \
		       libjansson4 \
                       ; \
    apt-get autoremove -y ; \
    apt-get clean -y ;

# copy LDMS binaries
COPY --from=build /opt/ovis/bin/ /opt/ovis/bin/
COPY --from=build /opt/ovis/sbin/ /opt/ovis/sbin/
COPY --from=build /opt/ovis/lib/ /opt/ovis/lib/
COPY --from=build /opt/ovis/etc/ /opt/ovis/etc/
COPY --from=build /opt/ovis/ui/ /opt/ovis/ui/

# setup LDMS env
RUN ln -s /opt/ovis/etc/profile.d/set-ovis-variables.sh /etc/profile.d/ ; \
    ln -s /opt/ovis/etc/ld.so.conf.d/ovis-ld-so.conf /etc/ld.so.conf.d/z-ovis-ld-so.conf ; \
    ldconfig ;
ENV PATH=/opt/ovis/bin:/opt/ovis/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV PYTHONPATH=/opt/ovis/lib/python3.10/site-packages:/opt/ovis/lib/python3.10/dist-packages
ENV LDMSD_PLUGIN_LIBPATH=/opt/ovis/lib/ovis-ldms
ENV ZAP_LIBPATH=/opt/ovis/lib/ovis-ldms

RUN echo > /start-uwsgi-sosgui.sh -e "#!/bin/bash\n\
mkdir -p /var/log/sosgui\n\
cd /opt/ovis/ui\n\
OPTS=( \"\$@\" )\n\
[[ \" \${OPTS[*]} \" == *\\ --http-socket* ]] || OPTS+=( --http-socket=:80 )\n\
[[ \" \${OPTS[*]} \" == *\\ --plugins* ]] || OPTS+=( --plugins=python3 )\n\
[[ \" \${OPTS[*]} \" == *\\ --module* ]] || OPTS+=( --module=sosgui.wsgi )\n\
uwsgi \"\${OPTS[@]}\" 2>&1 | tee /var/log/uwsgi.log\n\
" ; \
chmod 755 /start-uwsgi-sosgui.sh

ENTRYPOINT [ "/start-uwsgi-sosgui.sh" ]
