# ovishpc/ldmscon2023
#
# The docker context is prepared by './docker-build.sh'.

FROM ovishpc/ldms-dev:4.3.11-amd64

SHELL [ "/bin/bash", "-c" ]

# Get LDMS dependencies
RUN export DEBIAN_FRONTEND=noninteractive ; \
    apt-get update -y ; \
    apt-get install -y rpcbind \
		       uwsgi uwsgi-plugin-python3 \
		       python3-django python3-django-cors-headers \
		       python3 python3-pip python3-yaml etcd \
		       pdsh \
                       ; \
    apt-get autoremove -y ; \
    apt-get clean -y ;

RUN pip3 install protobuf==3.20 etcd3

# Default /etc/etcd.yaml (empty) for etcd
RUN touch /etc/etcd.yaml

# copy LDMS binaries
ADD  --chown=root:root  bin      /opt/ovis/bin/
ADD  --chown=root:root  etc      /opt/ovis/etc/
ADD  --chown=root:root  include  /opt/ovis/include/
ADD  --chown=root:root  lib      /opt/ovis/lib/
ADD  --chown=root:root  sbin     /opt/ovis/sbin/
ADD  --chown=root:root  share    /opt/ovis/share/
ADD  --chown=root:root  ui       /opt/ovis/ui/

# LDMSCON2023 contents in root's home
ADD  --chown=root:root  root     /root/


# setup LDMS env
RUN ln -s /opt/ovis/etc/profile.d/set-ovis-variables.sh /etc/profile.d/ ; \
    ln -s /opt/ovis/etc/ld.so.conf.d/ovis-ld-so.conf /etc/ld.so.conf.d/z-ovis.so.conf ; \
    ldconfig ;
ENV PATH=/opt/ovis/bin:/opt/ovis/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV PYTHONPATH=/opt/ovis/lib/python3.10/site-packages:/opt/ovis/lib/python3.10/dist-packages
ENV LDMSD_PLUGIN_LIBPATH=/opt/ovis/lib/ovis-ldms
ENV ZAP_LIBPATH=/opt/ovis/lib/ovis-ldms

RUN dd if=/dev/zero of=/etc/munge/munge.key bs=4096 count=1

RUN echo > /opt/ovis/ui/start-uwsgi-sosgui.sh -e "#!/bin/bash\n\
mkdir -p /var/log/sosgui\n\
cd /opt/ovis/ui\n\
OPTS=( \"\$@\" )\n\
[[ \" \${OPTS[*]} \" == *\\ --http-socket* ]] || OPTS+=( --http-socket=:80 )\n\
[[ \" \${OPTS[*]} \" == *\\ --plugins* ]] || OPTS+=( --plugins=python3 )\n\
[[ \" \${OPTS[*]} \" == *\\ --module* ]] || OPTS+=( --module=sosgui.wsgi )\n\
uwsgi \"\${OPTS[@]}\" 2>&1 | tee /var/log/uwsgi.log\n\
" ; \
chmod 755 /opt/ovis/ui/start-uwsgi-sosgui.sh

RUN mkdir /run/munge
RUN chmod 755 /run/munge
RUN chown munge:munge /run/munge

RUN /usr/bin/sed -i 's/# \(.* history-search.*\)/\1/' /etc/inputrc

RUN echo > /etc/profile.d/pdsh.sh -e "#!/bin/bash\n\
export PDSH_RCMD_TYPE=ssh\n\
" ; \

ENTRYPOINT [ "/bin/bash" ]
