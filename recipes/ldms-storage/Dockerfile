# ovishpc/ldms-agg
#
# The docker context is prepared by './docker-build.sh'.

FROM ubuntu:22.04

SHELL [ "/bin/bash", "-c" ]

RUN export DEBIAN_FRONTEND=noninteractive ; \
    apt-get update -y ; \
    apt-get install -y munge \
                       python3 python3-numpy python3-pandas \
		       rpcbind curl \
		       openjdk-11-jdk \
		       avro-bin python3-avro \
		       libjansson4 \
                       ; \
    apt-get autoremove -y ; \
    apt-get clean -y ;

RUN /bin/bash -c ' \
pushd /opt/ ;\
curl -LO https://archive.apache.org/dist/kafka/2.1.0/kafka_2.12-2.1.0.tgz ;\
tar xzf kafka_2.12-2.1.0.tgz ; \
mkdir kafka_2.12-2.1.0/logs/ ; \
'

# copy binaries
ADD --chown=root:root bin /opt/ovis/bin/
ADD --chown=root:root lib /opt/ovis/lib/
ADD --chown=root:root usr /usr/

# setup LDMS env
RUN echo > /etc/ld.so.conf.d/ovis.so.conf -e "/opt/ovis/lib"
RUN ldconfig ;
ENV PATH=/opt/ovis/bin:/opt/ovis/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV PYTHONPATH=/opt/ovis/lib/python3.10/site-packages:/opt/ovis/lib/python3.10/dist-packages

RUN echo > /etc/profile.d/ovis.sh -e "\
export PATH=/opt/ovis/bin:/opt/ovis/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\n\
export PYTHONPATH=/opt/ovis/lib/python3.10/site-packages:/opt/ovis/lib/python3.10/dist-packages\n\
"

RUN dd if=/dev/zero of=/etc/munge/munge.key bs=4096 count=1
