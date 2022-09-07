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

Sections:
- [Sites WITHOUT internet access](#sites-without-internet-access)
- [SYNOPSIS](#SYNOPSIS)
- [EXAMPLES](#EXAMPLES)
- [LDMS Sampler Container](#ldms-sampler-container)
- [LDMS Aggregator Container](#ldms-aggregator-container)
- [Maestro Container](#maestro-container)
- [LDMS UI Back-End Container](#ldms-ui-back-end-container)
- [LDMS-Grafana Container](#ldms-grafana-container)
- [SSH port forwarding to grafana](#ssh-port-forwarding-to-grafana)
- [Building Containers](#building-containers)

Sites WITHOUT internet access
-----------------------------
1. On your laptop (or a machine that HAS the Internet access)
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

2. On the site that has NO Internet access
```sh
$ docker load < ovishpc-ldms-dev.tar
$ docker load < ovishpc-ldms-samp.tar
$ docker load < ovishpc-ldms-agg.tar
$ docker load < ovishpc-ldms-maestro.tar
$ docker load < ovishpc-ldms-ui.tar
$ docker load < ovishpc-ldms-grafana.tar
```

Then, the images are available locally (no need to `docker pull`).


SYNOPSIS
--------
In this section, the options in `[ ]` is optional. Please see the `#` comments
right after the options for the description. Please also note that the options
BEFORE the Docker Image name are for `docker run`, and the options AFTER the
image name are for the entrypoint script. The following is the information
regarding entrypoint options for each image:
- `ovishpc/ldms-dev` entrypoint options are pass-through to `/bin/bash`.
- `ovishpc/ldms-samp` entrypoint options are pass-through to ldmsd.
- `ovishpc/ldms-agg` entrypoint options are pass-through to ldmsd.
- `ovishpc/ldms-maestro` entrypoint options are ignored.
- `ovishpc/ldms-ui` entrypoint options are pass-through to uwsgi.
- `ovishpc/ldms-grafana` entrypoint options are pass-through to grafana-server program.

```sh
# Pulling images
$ docker pull ovishpc/ldms-dev:wip
$ docker pull ovishpc/ldms-samp:wip
$ docker pull ovishpc/ldms-agg:wip
$ docker pull ovishpc/ldms-maestro:wip
$ docker pull ovishpc/ldms-ui:wip
$ docker pull ovishpc/ldms-grafana:wip

# munge remark: munge.key file must be owned by 101:101 (which is munge:munge in
#               the container) and has 0600 mode.

# ovishpc/ldms-maestro
$ docker run -d --name=<CONTAINER_NAME> --network=host --privileged
         [ -v /run/munge:/run/munge:ro ] # expose host's munge to the container
         [ -v /on-host/munge.key:/etc/munge/munge.key:ro ] # use container's munged with custom key
         -v /on-host/ldms_cfg.yaml:/etc/ldms_cfg.yaml:ro # bind ldms_cfg.yaml, used by maestro_ctrl
         ovishpc/ldms-maestro:wip # the image name


# ovishpc/ldms-samp
$ docker run -d --name=<CONTAINER_NAME> --network=host --pid=host --privileged
         -e COMPID=<NUMBER> # set COMPID environment variable
         [ -v /run/munge:/run/munge:ro ] # expose host's munge to the container
         [ -v /on-host/munge.key:/etc/munge/munge.key:ro ] # use container's munged with custom key
         ovishpc/ldms-samp:wip # the image name
              -x sock:411  # sock transport, listening on port 411
              [ -a munge ] # use munge authentication
              [ OTHER LDMSD OPTIONS ]


# ovishpc/ldms-agg
$ docker run -d --name=<CONTAINER_NAME> --network=host --pid=host --privileged
         -e COMPID=<NUMBER> # set COMPID environment variable
         [ -v /on-host/storage:/storage:rw ] # bind 'storage/'. Could be any path, depending on ldmsd configuration
         [ -v /on-host/dsosd.json:/etc/dsosd.json:ro ] # bind dsosd.json configuration, if using dsosd to export SOS data
         [ -v /run/munge:/run/munge:ro ] # expose host's munge to the container
         [ -v /on-host/munge.key:/etc/munge/munge.key:ro ] # use container's munged with custom key
         ovishpc/ldms-samp:wip # the image name
              -x sock:411  # sock transport, listening on port 411
              [ -a munge ] # use munge authentication
              [ OTHER LDMSD OPTIONS ]
# Run dsosd to export SOS data
$ docker exec -it <CONTAINER_NAME> /bin/bash
(<CONTAINER_NAME>) $ rpcbind
(<CONTAINER_NAME>) $ export DSOSD_DIRECTORY=/etc/dsosd.json
(<CONTAINER_NAME>) $ dsosd >/var/log/dsosd.log 2>&1 &
(<CONTAINER_NAME>) $ exit


# ovishpc/ldms-ui
$ docker run -d --name=<CONTAINER_NAME> --network=host --privileged
         -v /on-host/dsosd.conf:/opt/ovis/etc/dsosd.conf # dsosd.conf file, required to connect to dsosd
         -v /on-host/settings.py:/opt/ovis/ui/sosgui/settings.py # sosdb-ui Django setting file
         ovishpc/ldms-ui:wip # the image name
             [ --http-socket=<ADDR>:<PORT> ] # addr:port to serve, ":80" by default
             [ OTHER uWSGI OPTIONS ]


# ovishpc/ldms-grafana
$ docker run -d --name=<CONTAINER_NAME> --network=host --privileged
         [ -v /on-host/grafana.ini:/etc/grafana/grafana.ini:ro ] # custom grafana config
         [ -e GF_SERVER_HTTP_ADDR=<ADDR> ] # env var to override Grafana IP address binding (default: all addresses)
         [ -e GF_SERVER_HTTP_PORT=<PORT> ] # env var to override Grafana port binding (default: 3000)
         ovishpc/ldms-grafana # the image name
              [ OTHER GRAFANA-SERVER OPTIONS ] # other options to grafana-server


# -------------------------------------
#      configuration files summary
# -------------------------------------
# - /on-host/dsosd.json: contains dictionary mapping hostname - container
#   location in the host, e.g.
#   {
#     "host1": {
#       "dsos_cont":"/storage/cont_host1"
#     },
#     "host2": {
#       "dsos_cont":"/storage/cont_host2"
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


EXAMPLES
--------
```sh
# maestro - a daemon to configure ldmsd's.
#           run on an any system that can talk to all ldmsd's.
$ docker run -d --network=host -v /on-host/ldms_cfg.yaml:/etc/ldms_cfg.yaml:rw \
         ovishpc/ldms-maestro:wip

# maestro, using munge on the host (exposing host's /run/munge to the container)
$ docker run -d --network=host -v /on-host/ldms_cfg.yaml:/etc/ldms_cfg.yaml:rw \
         -v /run/munge:/run/munge:ro \
         ovishpc/ldms-maestro:wip

# maestro, with munged in a container + custom munge.key. The munge.key file
#   must be owned by 101:101 (munge:munge in the container) and has 0600 mode.
$ docker run -d --network=host -v /on-host/ldms_cfg.yaml:/etc/ldms_cfg.yaml:rw \
         -v /path/to/munge.key:/etc/munge/munge.key:ro \
         ovishpc/ldms-maestro:wip

# sampler on compute nodes, listening on port 411, no authentication;
#   COMPID is HOSTNAME with 'bitzer' prefix removed
$ docker run -d --name=samp --network=host --pid=host --privileged \
         -e COMPID=${HOSTNAME#bitzer} \
         ovishpc/ldms-samp:wip -x sock:411

# sampler on compute nodes, listening on port 411, with host's munge;
#   COMPID is HOSTNAME with 'bitzer' prefix removed
$ docker run -d --name=samp --network=host --pid=host --privileged \
         -v /run/munge:/run/munge:ro \
         -e COMPID=${HOSTNAME#bitzer} \
         ovishpc/ldms-samp:wip -x sock:411 -a munge

# sampler on compute nodes, listening on port 411, with munged in the container
#   and custom munge.key. The munge.key file must be owned by 101:101
#   (munge:munge in the container) and has 0600 mode.
#   COMPID is HOSTNAME with 'bitzer' prefix removed.
$ docker run -d --name=samp --network=host --pid=host --privileged \
         -v /path/to/munge.key:/etc/munge/munge.key:ro \
         -e COMPID=${HOSTNAME#bitzer} \
         ovishpc/ldms-samp:wip -x sock:411 -a munge

# aggregator, WITHOUT storage; with munged in the container with default key
$ docker run -d --name=agg1 --network=host --privileged \
         ovishpc/ldms-agg:wip -x sock:411 -a munge

# aggregator, WITH storage; with host munge
$ docker run -d --name=agg2 --network=host --privileged \
         -v /on-host/dsosd.json:/etc/dsosd.json:rw \
         -v /on-host/storage:/storage:rw \
         -v /run/munge:/run/munge:ro \
         ovishpc/ldms-agg:wip -x sock:411 -a munge
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

```

LDMS Sampler Container
----------------------
```sh
# SYNOPSIS
$ docker run -d --name=<CONTAINER_NAME> --network=host --pid=host --privileged
         -e COMPID=<NUMBER> # set COMPID environment variable
         [ -v /run/munge:/run/munge:ro ] # expose host's munge to the container
         [ -v /on-host/munge.key:/etc/munge/munge.key:ro ] # use container's munged with custom key
         ovishpc/ldms-samp:wip # the image name
              -x sock:411  # sock transport, listening on port 411
              [ -a munge ] # use munge authentication
              [ OTHER LDMSD OPTIONS ] # e.g. -v INFO

```
`ovishpc/ldms-samp:wip` entrypoint executes `ldmsd -F`, making it
the leader process of the container. Users can append `[OPTIONS]` and they will
be passed to `ldmsd -F` CLI. If `-a munge` is given, the entrypoint script will
check if `/run/munge` is a bind-mount from the host. If so, munge
encoding/decoding is done through `munged` on the host via the bind-mounged
`/run/munge` -- no need to run `munged` inside the container. Otherwise, in the
case that `-a munge` is given and `/run/munge` is not host-bind-mounted,
the entrypoint script runs `munged` and tests it BEFORE `ldmsd`.

Usage examples:
```sh
## On a compute node

# Pull the container image
$ docker pull ovishpc/ldms-samp:wip

# Start ldmsd container, with host network namespace and host PID namespace;
# - COMPID env var is HOSTNAME without the non-numeric prefixes and the leading
#   zeroes (e.g. nid00100 => 100, nid10000 => 10000). Note that this uses
#   bash(1) Parameter Expansion and Pattern Matching features.
#
# - serving on socket transport port 411 with munge authentication
#
# - using host munge
$ docker run -d --name=samp --network=host --pid=host --privileged \
         -e COMPID=${HOSTNAME##*([^1-9])} \
         -v /run/munge:/run/munge:ro \
         ovishpc/ldms-samp:wip -x sock:411 -a munge
```

We encourage to use `maestro` to configure a cluster of `ldmsd`. However, if
there is a need to configure `ldmsd` manually, one can do from within the
container. In this case:

```sh
$ docker exec samp /bin/bash
(samp) $ ldmsd_controller --xprt sock --port 411 --host localhost --auth munge
LDMSD_CONTROLLER_PROMPT>
```

LDMS Aggregator Container
-------------------------
```sh
# SYNOPSIS
$ docker run -d --name=<CONTAINER_NAME> --network=host --pid=host --privileged
         -e COMPID=<NUMBER> # set COMPID environment variable
         [ -v /on-host/storage:/storage:rw ] # bind 'storage/'. Could be any path, depending on ldmsd configuration
         [ -v /on-host/dsosd.json:/etc/dsosd.json:ro ] # bind dsosd.json configuration, if using dsosd to export SOS data
         [ -v /run/munge:/run/munge:ro ] # expose host's munge to the container
         [ -v /on-host/munge.key:/etc/munge/munge.key:ro ] # use container's munged with custom key
         ovishpc/ldms-samp:wip # the image name
              -x sock:411  # sock transport, listening on port 411
              [ -a munge ] # use munge authentication
              [ OTHER LDMSD OPTIONS ]
# dsosd to export SOS data
$ docker exec -it <CONTAINER_NAME> /bin/bash
(<CONTAINER_NAME>) $ rpcbind
(<CONTAINER_NAME>) $ export DSOSD_DIRECTORY=/etc/dsosd.json
(<CONTAINER_NAME>) $ dsosd >/var/log/dsosd.log 2>&1 &
(<CONTAINER_NAME>) $ exit

```
`ovishpc/ldms-agg:wip` entrypoint executes `ldmsd -F`, making it the
leader process of the container. It also handles `-a munge` the same way that
`ovishpc/ldms-samp:wip` does. In the case of exporting SOS data through `dsosd`,
the daemon is required to execute after the container is up.

Example usage:
```sh
## On a service node

# Pull the container image
$ docker pull ovishpc/ldms-agg:wip

# Start ldmsd container, using host network namespace and host PID namespace;
# - with host munge
# - serving port 411
# - The `-v  /on-host/storage:/storage:rw` option is to map on-host storage
#   location `/on-host/storage` to `/storage` location in the container. The
#   data written to `/storage/` in the container will persist in
#   `/on-host/storage/` on the host.
$ docker run -d --name=agg --network=host --privileged \
         -v /run/munge:/run/munge:ro \
	 -v /on-host/storage:/storage:rw \
         ovishpc/ldms-agg:wip -x sock:411 -a munge

# Start dsosd service for remote SOS container access (e.g. by UI), by first
# bring up a shell inside the container, then start rpcbind and dsosd.
$ docker exec agg /bin/bash
(agg) $ rpcbind
(agg) $ export DSOSD_DIRECTORY=/etc/dsosd.json
(agg) $ dsosd >/var/log/dsosd.log 2>&1 &
(agg) $ exit
```

`dsosd.json` contains a collection of `container_name` - `path` mappings for
each host. For example:
```json
{
  "host1": {
    "dsos_cont":"/storage/cont_host1",
    "tmp_cont":"/tmp/ram_cont"
  },
  "host2": {
    "dsos_cont":"/storage/cont_host2",
    "tmp_cont":"/tmp/ram_cont"
  }
}
```


Maestro Container
-----------------
```sh
# SYNOPSIS
$ docker run -d --name=<CONTAINER_NAME> --network=host --privileged
         [ -v /run/munge:/run/munge:ro ] # expose host's munge to the container
         [ -v /on-host/munge.key:/etc/munge/munge.key:ro ] # use container's munged with custom key
         -v /on-host/ldms_cfg.yaml:/etc/ldms_cfg.yaml:ro # bind ldms_cfg.yaml, used by maestro_ctrl
         ovishpc/ldms-maestro:wip # the image name
```
`ovishpc/ldms-maestro` containers will run at the least two daemons: `etcd` and
`maestro`. It may also run `munged` if host's munge is not used (i.e.
`-v /run/munge:/run/munge:ro` is not given to `docker run`).
The entrypoint script does the following:
1. starts `etcd`
2. starts `munged` if host's munge is not used.
3. execute `maestro_ctrl` with `--ldms_config /etc/ldms_cfg.yaml`. Notice that
   the `ldms_cfg.yaml` file is given by the user by the `-v` option.
4. execute `maestro` process. `maestro` will periodically connect to all `ldmsd`
   specified by `ldms_cfg.yaml` and send the corresponding configuration.

REMARK: For now, the `etcd` and `maestro` processes in the
`ovishpc/ldms-maestro` container run as stand-alone processes. We will support a
cluster of `ovishpc/ldms-maestro` containers in the future.

Example usage:
```sh
## On a service node

# Pull the container image
$ docker pull ovishpc/ldms-maestro:wip

# Start maestro container, using host network namespace, and using host's munge
$ docker run -d --network=host --privileged \
         -v /run/munge:/run/munge:ro \
	 -v /my/ldms_cfg.yaml:/etc/ldms_cfg.yaml:rw \
         ovishpc/ldms-maestro:wip
```

Please see [ldms_cfg.yaml](test/test-maestro/files/ldms_cfg.yaml) for an
example.


LDMS UI Back-End Container
--------------------------
```sh
# SYNOPSIS
$ docker run -d --name=<CONTAINER_NAME> --network=host --privileged
         -v /on-host/dsosd.conf:/opt/ovis/etc/dsosd.conf # dsosd.conf file, required to connect to dsosd
         -v /on-host/settings.py:/opt/ovis/ui/sosgui/settings.py # sosdb-ui Django setting file
         ovishpc/ldms-ui:wip # the image name
             [ --http-socket=<ADDR>:<PORT> ] # addr:port to serve, ":80" by default
             [ OTHER uWSGI OPTIONS ]
```
`ovishpc/ldms-ui:wip` execute `uwsgi` process with `sosgui` (the back-end
GUI WSGI module) application module. It is the only process in the container.
The `uwsgi` in this container by default will listen to port 80. The
`--http-socket=ADDR:PORT` will override this behavior. Other options given to
`docker run` will also be passed to the `uwsgi` command as well.

The `sosgui` WSGI application requires two configuration files:
1. `dsosd.conf`: containing a list of hostnames of dsosd, one per line. See
   [here](test/test-maestro/files/dsosd.conf) for an example.
2. `settings.py`: containing a WSGI application settings. Please pay attention
   to DSOS_ROOT and DSOS_CONF. See [here](test/test-maestro/files/settings.py)
   for an example.

Usage example:
```sh
## On a service node

# Pull the container image
$ docker pull ovishpc/ldms-ui:wip

# Start ldms-ui container, using host network namespace
$ docker run -d --name=ui --network=host --privileged \
	   -v /HOST/dsosd.conf:/opt/ovis/etc/dsosd.conf \
	   -v /HOST/settings.py:/opt/ovis/ui/sosgui/settings.py \
         ovishpc/ldms-ui:wip
```

LDMS-Grafana Container
----------------------
```sh
# SYNOPSIS
$ docker run -d --name=<CONTAINER_NAME> --network=host --privileged
         [ -v /on-host/grafana.ini:/etc/grafana/grafana.ini:ro ] # custom grafana config
         [ -e GF_SERVER_HTTP_ADDR=<ADDR> ] # env var to override Grafana IP address binding (default: all addresses)
         [ -e GF_SERVER_HTTP_PORT=<PORT> ] # env var to override Grafana port binding (default: 3000)
         ovishpc/ldms-grafana # the image name
              [ OTHER GRAFANA-SERVER OPTIONS ] # other options to grafana-server
```

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
$ docker run -d --name=grafana --privileged --network=host ovishpc/ldms-grafana

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
