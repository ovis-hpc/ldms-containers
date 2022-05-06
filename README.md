LDMS Containers
==============

This repository contains scripts and recipes to build various `ovishpc/ldms-*`
docker images, and the scripts to run them. TODO: PURPOSES / ASSUMPTIONS.

The following is a list of images:
* `ovishpc/ldms-base` - the base container image containing common prerequisites
      for `ovishpc/ldms-samp` and `ovishpc/ldms-agg`.
   * see `ldms-base/docker-build.sh` and `ldms-base/Dockerfile`.
* `ovishpc/ldms-samp` - the container image for sampler daemons.
   * see `ldms-samp/docker-build.sh` and `ldms-samp/Dockerfile`.
* `ovishpc/ldms-agg` - the container image for aggregator daemons, optionally
      with storage.
* `ovishpc/ldms-ui` - the container image for Django `sosdb-ui` backend.
* `ovishpc/ldms-grafana` - the container image for Grafana web app.

You can simply pull these pre-built images from the docker hub:
```sh
$ docker pull ovishpc/ldms-samp
$ docker pull ovishpc/ldms-agg
$ docker pull ovishpc/ldms-ui
$ docker pull ovishpc/ldms-grafana
```

To build the images locally, please see the [Building Images](#building-images)
section.


Building Images
===============

Building all images from the top directory can be achieved by the following:
```sh
# First, build OVIS binaries
$ ./ovis-build.sh

# Then, build the docker containers
$ ./docker-build.sh
```

The ovis binaries are built in a separate build-container so that we don't have
to install the build dependencies in the target containers. The top-level
`ovis-build.sh` sequentially calls `ldms-samp/ovis-build.sh`,
`ldms-agg/ovis-build.sh`, and `ldms-ui/ovis-build.sh`
(`ldms-base` and `ldms-grafana` does not need ovis-build routine).
* `ldms-samp/ovis-build.sh` builds ovis binaries with sampler plugins. It does
  not contain any storage plugins.
* `ldms-agg/ovis-build.sh` builds ovis binaries with sampler plugins and storage
  plugins (`sos`, `csv`, `function_csv` and their dependencies).
* `ldms-ui/ovis-build.sh` builds `numsos`, `sosdb-ui`, and `sosdb-grafana`
  binaries that, in combination, serve data from `sos` (or `dsosd`) to
  `ldms-grafana` container. `ldms-ui/ovis-build.sh` uses the ovis binaries from
  `ldms-agg/ovis-build.sh` as its build base.

The `docker-build.sh` sequentially calls `ldms-base/docker-build.sh`,
`ldms-samp/docker-build.sh`, `ldms-agg/docker-build.sh`,
`ldms-ui/docker-build.sh`, and `ldms-grafana/docker-build.sh` to build
respective docker images.
* `ldms-base/docker-build.sh` build `ovishpc/ldms-base` docker image that is the
  base for `ovishpc/ldms-samp` and `ovishpc/ldms-agg`.
* `ldms-samp/docker-build.sh` build `ovishpc/ldms-samp` docker image with the
  ovis binaries generated from `ldms-samp/ovis-build.sh`.
* `ldms-agg/docker-build.sh` build `ovishpc/ldms-agg` docker image with the
  ovis binaries generated from `ldms-agg/ovis-build.sh`.
* `ldms-ui/docker-build.sh` build `ovishpc/ldms-ui` docker image with the
  ovis & ui binaries generated from `ldms-ui/ovis-build.sh`.
* `ldms-grafana/docker-build.sh` build `ovishpc/ldms-grafana` docker image based
  on the official grafana `grafana/grafana-oss` image, with customized
  entrypoint script appropriate for our project.


Preparing Docker
================

* `ldms-containers` need docker swarm for inter-container communication. So, if
  docker swarm has not yet initialized, please do so by:
  ```sh
  $ docker swarm init
  ```

  Also, the other barebone hosts that may run ldms-containers have to be in the
  swarm network as well (otherwise, the containers on those hosts won't be able
  to talk to the containers on this host). Please see `docker-swarm-join(1)` for
  more information.

* `ldms-containers` require an overlay network with "swarm" scope. Please edit
  `config.sh` and set `NET` (the name of the overlay network) and `SUBNET` (the
  IP addresses for the overlay network) to your liking, then execute
  `network-create.sh` script.


Running sampler containers
==========================

By default, `ovishpc/ldms-samp` is run with privileged and in the same
namespaces (pid, network, uts, and ipc namespaces) as the host so that the
container's `/proc` and `/sys` are the same as host's. `--no-host-namespaces`
option can be given to disable the privileged and configuring the container to
run in its own namespaces. Note that in this case, some information in `/proc`
and `/sys` in the container will be different from the host's (e.g.
`/proc/net/dev`).

Issue the following `./ldms-samp/run.sh` command on the baremetal hosts that
will run the sampler container. For example:
```sh
# on node-1
node-01 $ ./ldms-samp/run.sh --samp "loadavg meminfo vmstat"


# on node-2
node-02 $ ./ldms-samp/run.sh --samp "loadavg meminfo vmstat"
```
Without the `--name` parameter, the default name is the `$HOSTNAME`.
The above example run `node-01` container on `node-01` and `node-02` container
on `node-02` with 3 sampler plugins: loadavg, meminfo and vmstat. Please note
that the sampler plugins specified here must be a "simple" plugins, i.e. they
only need 'load', 'config', 'start' ldmsd commands with basic parameters.

In the case of complex configuration, the config file in the container can be
overridden by:
```sh
$ ./ldms-samp/run.sh \
    -v /PATH/TO/CONFIG/ON/HOST:/opt/ovis/etc/ldms.conf
```

`--pdsh PDSH_HOSTLIST` can be supplied to remotely execute `docker run` to
deploy the containers on the specified hosts. For example,
```sh
headnode $ ./ldms-samp/run.sh --pdsh "ssh:nid[00001-20]" --samp "loadavg meminfo"
```
The command executes `docker run` on nid00001, ..., nid00020 over with `pdsh`
over SSH, deploying ldms-samp containers (with the same name as hostname) with
loadavg and meminfo samplers (default port 411, auth none).

For more information, please see USAGE in `ldms-samp/run.sh`.


Running aggregator containers without storage plugin
=====================================================

```sh
$ ./ldms-agg/run.sh --name agg-11 --prdcr "samp-{01..20}" --mem 128M \
		    --offset 200000
```
This will run an aggregator container without storage plugin. The `prdcr` option
tells `ldmsd` to collect LDMS sets from `samp-01`, `samp-02`, ..., `samp-20`
containers. The `mem` option tells the `ldmsd` inside the container to allocate
the memory pool of the given size to hold LDMS sets from many samplers. The
`offset` option tells the updater in the `ldmsd` in the container to update the
sets with 200 ms offset.

For more information, please see USAGE in `ldms-agg/run.sh`.


Running aggregator containers with storage plugin
=================================================

```sh
$ ./ldms-agg/run.sh --name agg-21 --prdcr "agg-{11,12}" --mem 256M \
                    --strgp "loadavg meminfo vmstat" --offset 400000
```
This runs an aggregator container, named `agg-21`, collecting LDMS sets from
`agg-11` and `agg-12`. The `strgp` option configure `ldmsd` in the `agg-21`
container to load `store_sos` and add storage policies that collect data from
`loadavg`, `meminfo` and `vmstat` schema. When running an aggregator with
`store_sos`, `dsosd` will automatically run to export the SOS data over RPC.

For more information, please see USAGE in `ldms-agg/run.sh`.


Running ui container
====================

```sh
$ ./ldms-ui/run.sh --name ui --dsosd "agg-{21,22}"
```
This run a `ui` container with Django backend. The `dsosd` option configure the
Django backend to connect to dsosd on `agg-21` and `agg-22` to get SOS data.

For more information, please see USAGE in `ldms-ui/run.sh`.


Running grafana container
=========================

```sh
$ ./ldms-grafana/run.sh --name grafana
```
This runs the `grafana` container. The `http://ui/grafana/` data source has been
pre-added. If the `ui` container run under different name, the data source needs
to be modified.

The `grafana` container is also configured to serve over a Unix domain socket
instead of the TCP port 3000 to work around a firewall issue. The location of
the socket is located at `ldms-grafana/sock/grafana/grafana.sock` (actually
`ldms-grafana/sock/<CONTAINER_NAME>/grafana.sock`).

To port-forward to the grafana socket from one's laptop:

```sh
bob-laptop $ ssh -L 127.0.0.1:3000:/home/bob/ldms-grafana/sock/grafana/grafana.sock bob@somewhere.net
```

Now, `http://127.0.0.1:3000` on a web browser on Bob's laptop will show grafana
web UI.

Please see `ldms-grafana/run.sh` for more information.


For Voltrino
============

Please see `voltrino.sh` and `kill-voltrino.sh`.
