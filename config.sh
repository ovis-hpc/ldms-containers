#!/bin/bash
#
# This file contains environment variables used in:
# - scripts/build-ovis-binaries.sh
# - recipes/ldms-dev/docker-build.sh
# - recipes/ldms-samp/docker-build.sh
# - recipes/ldms-agg/docker-build.sh
# - recipes/ldms-ui/docker-build.sh
# - recipes/ldms-grafana/docker-build.sh
#
# The *_BRANCH values must be a branch name or a full 40-hex commit ID.

# All relative paths in this file is relative to top source dir (this directory)

# Path to ovis binaries (built by or to be built by
# `scripts/build-ovis-binaries.sh`)
OVIS=ovis

############################################
# ---- scripts/build-ovis-binaries.sh ---- #
############################################

# OVIS git repository and branch to check out from
#OVIS_REPO=https://github.com/ovis-hpc/ovis
#OVIS_BRANCH=OVIS-4
OVIS_REPO=https://github.com/ovis-hpc/ovis
OVIS_BRANCH=70ea2017de535bdb42bce3174c442280183efd08

# SOS git repository and branch to check out from
SOS_REPO=https://github.com/ovis-hpc/sos
SOS_BRANCH=f91f14136c1150311f5a42caa0b60f1a6cbdeb92

# Maestro git repository and branch to check out from
#MAESTRO_REPO=https://github.com/ovis-hpc/maestro
#MAESTRO_BRANCH=master
MAESTRO_REPO=https://github.com/ovis-hpc/maestro
MAESTRO_BRANCH=72e02e2a779060557699e2c50537a3d39c8fbe20

# The name of the container for building OVIS binaries. This can be anything.
BUILD_CONT=ldms-cont-ovis-build

# The build image containing OVIS build prerequisites.
BUILD_IMG=ovishpc/ldms-dev

# OVIS prefix INSIDE the container. Please do not change this.
PREFIX=/opt/ovis

# configure OPTIONS for SOS other than --prefix (*** This is a bash array ***)
SOS_OPTIONS=(
	CFLAGS=\"-O2\"
)

# configure OPTIONS for OVIS other than --prefix (*** This is a bash array ***)
OVIS_OPTIONS=(
	--enable-python
	--enable-etc
	--enable-doc
	--enable-doc-man

	# tests
	--enable-zaptest
	--enable-ldms-test
	--enable-test_sampler
	--enable-list_sampler
	--enable-record_sampler

	# extra xprt
	--enable-rdma

	# auth
	--enable-munge

	# stores
	--enable-sos
	--with-sos=${PREFIX}
	--enable-store-app
	--with-kafka=yes

	# samplers
	--enable-tutorial-sampler
	--enable-tutorial-store
	--enable-app-sampler
	--enable-papi

	CFLAGS=\"-O2\"
)

# ---- UI components ---- #
PREFIX_UI=${PREFIX}/ui
NUMSOS_REPO=https://github.com/nick-enoent/numsos
NUMSOS_BRANCH=b9d1742fe769c49216efa8c35624123e5b995926
NUMSOS_OPTIONS=()

SOSDBUI_REPO=https://github.com/nick-enoent/sosdb-ui
SOSDBUI_BRANCH=500069d5388fc8d68fe9ae0d6b847c8ce1da95c0
SOSDBUI_OPTIONS=()

SOSDBGRAFANA_REPO=https://github.com/nick-enoent/sosdb-grafana
SOSDBGRAFANA_BRANCH=e5eb5347f3864e2e3447e996cdbe28b8e74b2bb6
SOSDBGRAFANA_OPTIONS=()

#####################################
# ---- scripts/build-dsosds.sh ---- #
#####################################
# ---- dsos data source grafana plugin ---- #
DSOSDS=dsosds # the dsosds build dir relative to the top dir
DSOSDS_REPO=https://github.com/narategithub/dsosds
DSOSDS_BRANCH=1910e9a6d832b2114ab4421bbb61ea4de95b004d
DSOSDS_BUILD_CONT=dsosds-build
DSOSDS_BUILD_IMG=ovishpc/ldms-dev
