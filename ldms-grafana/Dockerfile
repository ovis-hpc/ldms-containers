FROM grafana/grafana-oss:8.0.2-ubuntu
SHELL [ "/bin/bash", "-c" ]

COPY --chown=grafana:root dsosds /var/lib/grafana/plugins/dsosds
COPY --chown=grafana:root conf/grafana.ini /etc/grafana/grafana.ini
COPY --chown=grafana:root conf/datasources.json /docker/datasources.json
COPY --chown=grafana:root scripts-grafana/start.sh /docker/start.sh

ENTRYPOINT [ "/docker/start.sh" ]
