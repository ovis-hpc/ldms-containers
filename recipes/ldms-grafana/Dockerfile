#FROM grafana/grafana-oss:8.0.2-ubuntu
FROM grafana/grafana-oss:9.1.0-ubuntu
SHELL [ "/bin/bash", "-c" ]

USER root
RUN echo > /etc/grafana/grafana.ini -e "\
[log]\n\
mode = file\n\
\n\
[plugins]\n\
allow_loading_unsigned_plugins = \"dsosds\"\n\
plugin_admin_enabled = true\n\
" ;

USER grafana
ADD * /var/lib/grafana/plugins/dsosds/
