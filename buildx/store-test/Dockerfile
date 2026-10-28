# BASE is expected to be a version of ovishpc/ldms-build

ARG BASE=ovishpc/ldms-build:main-${TARGETARCH}

FROM ${BASE}

RUN <<EOF
set -e
set -x
apt-get update -y
apt-get install -y protobuf-compiler
apt-get autoremove -y
apt-get autoclean -y
apt-get clean -y
EOF

# Build influxdb3 from source b/c influxdb docker container is built on
# Ubuntu 24.04. We're on Ubuntu 26.04. The installation of influxdb from APT
# repository interacts with systemd :(

RUN <<EOF
set -e
set -x
curl -sSf https://sh.rustup.rs | sh -s -- -y
EOF

# clone
RUN <<EOF
set -e
set -x
cd /root/
git clone https://github.com/influxdata/influxdb -b v3.11.5 --single-branch
EOF

# build
RUN <<EOF
cd /root/influxdb
source ~/.cargo/env
git checkout -b build
cargo build --release
cp target/release/influxdb3 /usr/local/bin/
mkdir -p /var/lib/influxdb3/data /var/lib/influxdb3/plugins
EOF

RUN pip3 install influxdb3-python --break-system-packages

RUN <<EOF
set -e
set -x
apt-get update -y
apt-get install -y rpcbind
apt-get autoremove -y
apt-get autoclean -y
apt-get clean -y
EOF
