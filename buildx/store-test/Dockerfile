# BASE is expected to be a version of ovishpc/ldms-build

ARG BASE=ovishpc/ldms-build:main-${TARGETARCH}
FROM ${BASE}

RUN mkdir -p /root/elk
RUN curl -L https://artifacts.elastic.co/GPG-KEY-elasticsearch -o /root/elk/elk.asc
RUN gpg --dearmor -o /usr/share/keyrings/elk-keyring.gpg  < /root/elk/elk.asc

COPY <<EOF /etc/apt/sources.list.d/elastic-9.x.list
deb [signed-by=/usr/share/keyrings/elk-keyring.gpg] https://artifacts.elastic.co/packages/9.x/apt stable main
EOF

RUN <<EOF
set -e
set -x
apt-get update
apt-get install -y elasticsearch
apt-get autoclean -y
apt-get clean -y
EOF

RUN mkdir -p /root/influxdata
RUN curl -L https://repos.influxdata.com/influxdata-archive_compat-exp2029.key -o /root/influxdata/influxdata.asc
RUN gpg --dearmor -o /etc/apt/trusted.gpg.d/influxdata.gpg < /root/influxdata/influxdata.asc

COPY <<EOF /etc/apt/sources.list.d/influxdata.list
deb [signed-by=/etc/apt/trusted.gpg.d/influxdata.gpg] https://repos.influxdata.com/debian stable main
EOF

RUN <<EOF
set -e
set -x
apt-get update
apt-get install -y influxdb2
apt-get autoclean -y
apt-get clean -y
EOF
