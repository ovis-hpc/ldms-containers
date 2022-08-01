#FROM grafana/grafana-oss:8.0.2-ubuntu
FROM grafana/grafana-oss:9.1.0-ubuntu
SHELL [ "/bin/bash", "-c" ]

USER root
RUN apt-get update ; \
    apt-get install -y git ; \
    apt-get clean ;

USER grafana
RUN mkdir -p /var/lib/grafana/plugins/dsosd ; \
    pushd /var/lib/grafana/plugins/dsosd ; \
    git init . ; \
    git remote add origin https://github.com/nick-enoent/dsosds.git ; \
    git fetch origin master ; \
    git checkout 521b50b6 ;

USER root
RUN echo > /etc/grafana/grafana.ini -e "\
[log]\n\
mode = file\n\
\n\
[plugins]\n\
allow_loading_unsigned_plugins = \"sosds\"\n\
plugin_admin_enabled = true\n\
" ;

#COPY --chown=grafana:root conf/datasources.json /docker/datasources.json

#COPY --chown=grafana:root scripts-grafana/start.sh /docker/start.sh

#ENTRYPOINT [ "/docker/start.sh" ]
USER grafana
