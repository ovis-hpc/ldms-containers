FROM ovishpc/ldms-base

SHELL [ "/bin/bash", "-c" ]

# Install numpy
RUN pip3 --no-cache-dir install numpy pandas

RUN yum install -y rpcbind ; \
    yum clean all ;

# create `/store` directory
RUN mkdir /store

# copy LDMS binaries & setup LDMS env
COPY --chown=root:root .ovis /opt/ovis
RUN ln -s /opt/ovis/etc/profile.d/set-ovis-variables.sh /etc/profile.d/ ; \
    ln -s /opt/ovis/etc/ld.so.conf.d/ovis-ld-so.conf /etc/ld.so.conf.d/ ; \
    ldconfig ;

# copy helper scripts
COPY --chown=root:root 	.scripts/ldmsd-start .scripts/ldmsd-conf \
			.scripts/dsosd-start \
			/opt/ovis/sbin/

# Prepare the startup script
COPY --chown=root:root .scripts/start.sh /docker/

ENTRYPOINT [ "/docker/start.sh" ]
