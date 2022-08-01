LDMS Containers
===============

REMARK: This document is still a work-in-progress for Ubuntu-based containers.

`ovis-hpc/ldms-containers` git repository contains recipes and scripts for
building Docker Images of various components in LDMS, namely:
  - `ovishpc/ldms-dev`: an image containing dependencies for building OVIS
      binaries and developing LDMS plugins.
  - `ovishpc/ldms-samp`: an image containing `ldmsd` binary and sampler plugins.
  - `ovishpc/ldms-agg`: an image containing `ldmsd` binary, sampler plugins,
      and storage plugins (including SOS).
  - `ovishpc/ldms-maestro`: an image containing `maestro` and `etcd`.
  - `ovishpc/ldms-ui`: an image containing UI back-end elements, providing LDMS
      data access over HTTP (`uwsgi` + `django` +
      [ovis-hpc/numsos](https://github.com/nick-enoent/numsos) +
      [ovis-hpc/sosdb-ui](https://github.com/nick-enoent/sosdb-ui) +
      [ovis-hpc/sosdb-grafana](https://github.com/nick-enoent/sosdb-grafana))
  - `ovishpc/ldms-grafana`: an image containing `grafana` and the SOS
      data source plugin for grafana ([sosds](https://github.com/nick-enoent/dsosds))

Sites with no internet access
-----------------------------
1. On your laptop (or a machine that has the Internet access)
```sh
$ docker pull ovishpc/ldms-dev:wip
$ docker pull ovishpc/ldms-samp:wip
$ docker pull ovishpc/ldms-agg:wip
$ docker pull ovishpc/ldms-maestro:wip
$ docker pull ovishpc/ldms-ui:wip
$ docker pull ovishpc/ldms-grafana:wip

$ docker save ovishpc/ldms-dev:wip > ovishpc-ldms-dev.tar
$ docker save ovishpc/ldms-samp:wip > ovishpc-ldms-samp.tar
$ docker save ovishpc/ldms-agg:wip > ovishpc-ldms-agg.tar
$ docker save ovishpc/ldms-maestro:wip > ovishpc-ldms-maestro.tar
$ docker save ovishpc/ldms-ui:wip > ovishpc-ldms-ui.tar
$ docker save ovishpc/ldms-grafana:wip > ovishpc-ldms-grafana.tar

# Then, copy these tar files to the site
```

2. On the site that has no Internet access
```sh
$ docker load < ovishpc-ldms-dev.tar
$ docker load < ovishpc-ldms-samp.tar
$ docker load < ovishpc-ldms-agg.tar
$ docker load < ovishpc-ldms-maestro.tar
$ docker load < ovishpc-ldms-ui.tar
$ docker load < ovishpc-ldms-grafana.tar
```

Then, you can skip the `docker pull` steps when deploying.


SYNOPSIS
--------
```sh
# maestro - a daemon to configure ldmsd's.
#           run on an any system that can talk to all ldmsd's.
$ docker run -d --network=host -v /on-host/ldms_cfg.yaml:/etc/ldms_cfg.yaml:rw \
         ovishpc/ldms-maestro:wip

# sampler on compute nodes, listening on port 411
$ docker run -d --name=samp --network=host --pid=host --privileged \
         -e COMPID=${HOSTNAME#bitzer} \
         ovishpc/ldms-samp:wip -x sock:411

# aggregator, WITHOUT storage
$ docker run -d --name=agg1 --network=host --privileged \
         ovishpc/ldms-agg:wip -x sock:411

# aggregator, WITH storage
$ docker run -d --name=agg2 --network=host --privileged \
         -v /on-host/dsosd.json:/etc/dsosd.json:rw \
         -v /on-host/storage:/storage:rw \
         ovishpc/ldms-agg:wip -x sock:411
# export dsosd
$ docker exec -it agg2 /bin/bash
(agg2) $ rpcbind
(agg2) $ export DSOSD_DIRECTORY=/etc/dsosd.json
(agg2) $ dsosd >/var/log/dsosd.log 2>&1 &
(agg2) $ exit

# ui back-end, will use port 80
$ docker run -d --network=host --privileged \
         -v /on-host/dsosd.conf:/opt/ovis/etc/dsosd.conf \
         -v /on-host/settings.py:/opt/ovis/ui/sosgui/settings.py \
         ovishpc/ldms-ui:wip

# grafana, will use port 3000
$ docker run -d --privileged --network=host ovishpc/ldms-grafana


# configuration files summary:
# - /on-host/dsosd.json: contains dictionary mapping hostname - container
#   location in the host, e.g.
#   {
#     "host1": {
#       "dsos_cont":"/storage/cont_host1"
#     },
#     "host2": {
#       "doss_cont":"/storage/cont_host2"
#     }
#   }
#
# - /on-host/dsosd.conf: contains host names (one per line) of the dsosd, e.g.
#   host1
#   host2
#
# - /on-host/settings.py: Django settings. Pay attention to DSOS_ROOT and
#   DSOS_CONF variables.
```

LDMS Sampler Container
----------------------

`ovishpc/ldms-samp:wip` entrypoint executes `ldmsd -F`, making it
the leader process of the container. Users can append `[OPTIONS]` and they will
be passed to `ldmsd -F` CLI. For the sampler, this is the only process
in the container.

```sh
## On a compute node

# Pull the container image
$ docker pull ovishpc/ldms-samp:wip

# Start ldmsd container, using host network namespace and host PID namespace
$ docker run -d --name=samp --network=host --pid=host --privileged ovishpc/ldms-samp:wip

# Or, with additional ldmsd options
$ docker run -d --name=samp --network=host --pid=host --privileged ovishpc/ldms-samp:wip [OPTIONS]

# For example:
$ docker run -d --name=samp --network=host --pid=host --privileged \
         ovishpc/ldms-samp:wip -x sock:411
```

The `OPTIONS` are the `ldmsd` options (e.g. `-v INFO`). The entrypoint in
`ovishpc/ldms-samp` starts `ldmsd -F` with additional options given at the
`docker run` command. If the options do not contain `-x`, a `-x sock:411` is
added by the entrypoint script. The entrypoint script finally `exec ldmsd`
with the constructed options. Please see `recipes/ldms-samp/Dockerfile` for more
information.


LDMS Aggregator Container
-------------------------
`ovishpc/ldms-agg:wip` entrypoint executes `ldmsd -F`, making it the
leader process of the container. If the aggregator does not export SOS storage,
the `ldmsd` is the only process in the container. Otherwise, `dsosd` can later
be `exec` to export the SOS containers.

```sh
## On a service node

# Pull the container image
$ docker pull ovishpc/ldms-agg:wip

# Start ldmsd container, using host network namespace and host PID namespace
$ docker run -d --name=agg1 --network=host --privileged \
	 -v /on-host/storage:/storage:rw \
         ovishpc/ldms-agg:wip -x sock:411
# The `-v` option is to map on-host storage location `/on-host/storage` to
# `/storage` location in the container if this aggregator also write data to the
# storage.

# Start dsosd service for remote SOS container access (e.g. by UI), by first
# bring up a shell inside the container, then start rpcbind and dsosd.
$ docker exec agg1 /bin/bash
(in-container) $ rpcbind
(in-container) $ export DSOSD_DIRECTORY=/etc/dsosd.json
(in-container) $ dsosd >/var/log/dsosd.log 2>&1 &
(in-container) $ exit
```

The `OPTIONS` are the `ldmsd` options (e.g. `-v INFO`). The entrypoint in
`ovishpc/ldms-agg` starts `ldmsd -F` with additional options given at the
`docker run` command. If the options do not contain `-x`, a `-x sock:411` is
added by the entrypoint script. The entrypoint script finally `exec ldmsd`
with the constructed options. Please see `recipes/ldms-agg/Dockerfile` for more
information.


Maestro Container
-----------------
`ovishpc/ldms-maestro` containers will run two daemons: `etcd` and `maestro`.
The entrypoint script does the following:
1. starts `etcd`
2. execute `maestro_ctrl` with `--ldms_config /etc/ldms_cfg.yaml`. Notice that
   the `ldms_cfg.yaml` file is given by the user by the `-v` option.
3. execute `maestro` process.

REMARK: For now, the `etcd` and `maestro` processes in the
`ovishpc/ldms-maestro` container run as stand-alone processes. We will support a
cluster of `ovishpc/ldms-maestro` containers in the near future.

```sh
## On a service node

# Pull the container image
$ docker pull ovishpc/ldms-maestro:wip

# Start maestro container, using host network namespace
$ docker run -d --network=host --privileged \
	 -v /my/ldms_cfg.yaml:/etc/ldms_cfg.yaml:rw \
         ovishpc/ldms-maestro:wip
```

Please see [ldms_cfg.yaml](test/test-maestro/files/ldms_cfg.yaml) for an
example.


UI Back-End Container
---------------------
`ovishpc/ldms-ui:wip` execute `uwsgi` process with `sosgui` (the back-end
GUI WSGI module). It is the only process in the container. The `uwsgi` in this
container by default will listen to port 80. The `--http-socket=ADDR:PORT` will
override this behavior. Other options given to `docker run` will also be passed
to the `uwsgi` command as well.

The `sosgui` WSGI application requires two configuration files:
1. `dsosd.conf`: containing a list of hostnames of dsosd, one per line. See
   [here](test/test-maestro/files/dsosd.conf) for an example.
2. `settings.py`: containing a WSGI application settings. Please pay attention
   to DSOS_ROOT and DSOS_CONF. See [here](test/test-maestro/files/settings.py)
   for an example.

```sh
## On a service node

# Pull the container image
$ docker pull ovishpc/ldms-ui:wip

# Start ldms-ui container, using host network namespace
$ docker run -d --network=host \
	   -v /HOST/dsosd.conf:/opt/ovis/etc/dsosd.conf \
	   -v /HOST/settings.py:/opt/ovis/ui/sosgui/settings.py \
         ovishpc/ldms-ui:wip [uWSGI_OPTIONS]
# dsosd.conf contains the names of the hosts that run dsosd, one name per line.
# settings.py is the django config file see test/test-maestro/files/settings.py
#   as an example.
```

LDMS-Grafana Container
----------------------
`ovishpc/ldms-grafana:wip` is based on
[grafana/grafana-oss:9.1.0-ubuntu](https://hub.docker.com/layers/grafana/grafana/grafana/9.1.0-ubuntu/images/sha256-39ea2186a2a5f04d808342400fe667678fd02632e62f2c36efa58c27a435d31d?context=explore)
with Sos data source plugin to access distributed-SOS data.
The grafana server listens to port 3000 by default. The options specified
at the `docker run` CLI will be passed to the `grafana-server` command.

```sh
## On a service node

# Pull the container image
$ docker pull ovishpc/ldms-grafana:wip

# Start ldms-grafana container, this will use port 3000
$ docker run -d --privileged --network=host ovishpc/ldms-grafana [OPTIONS]

# Use a web browser to navigate to http://HOSTNAME:3000 to access grafana
```


SSH port forwarding to grafana
------------------------------
In the case that the grafana server cannot be accessed directly, use SSH port
forwarding as follows:
```sh
(laptop) $ ssh -L 127.0.0.1:3000:127.0.0.1:3000 LOGIN_NODE
(LOGIN_HODE) $ ssh -L 127.0.0.1:3000:127.0.0.1:3000 G_HOST
# Assuming that the ldms-grafana container is running on G_HOST.
```
Then, you should be able to access the grafana web server via
`http://127.0.0.1:3000/` on your laptop.


Building Containers
-------------------
In short, edit [config.sh](config.sh), customize the `*_REPO`, `*_BRANCH` and
`*_OPTIONS`, then run `./scripts/build-all.sh`.

The loger version ... [TODO]
