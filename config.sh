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
ARCH=$(uname -m)
# translate Linux arch into docker-world arch
case "${ARCH}" in
	x86_64 )
		ARCH=amd64
		;;
	aarch64 )
		ARCH=arm64
		;;
esac
BUILD_TAG=custom-${ARCH}
MANIFEST_TAG=latest
MANIFEST_IMAGES=(
	ovishpc/ldms-{samp,agg}
	# ovishpc/ldms-dev
	# ovishpc/ldms-maestro
	# ovishpc/ldms-{web-svc,grafana}
	# ovishpc/ldms-storage
)
MANIFEST_ARCHS=( arm64 amd64 ppc64le )

############################################
# ---- scripts/build-ovis-binaries.sh ---- #
############################################

# OVIS git repository and branch to check out from
OVIS_REPO=https://github.com/ovis-hpc/ovis
OVIS_BRANCH=OVIS-4.3.11

# SOS git repository and branch to check out from
SOS_REPO=https://github.com/ovis-hpc/sos
# This was the top of sos/SOS-6
SOS_BRANCH=929fcc858bec6e263b2f91ff357d554ffb51f968

# Maestro git repository and branch to check out from
#MAESTRO_REPO=https://github.com/ovis-hpc/maestro
#MAESTRO_BRANCH=master
MAESTRO_REPO=https://github.com/ovis-hpc/maestro
# This was the top of maestro/master
MAESTRO_BRANCH=e009d4551aa86070bb1ea41daaa987b8af39fb53

# The name of the container for building OVIS binaries. This can be anything.
BUILD_CONT=ldms-cont-ovis-build

# The build image containing OVIS build prerequisites.
BUILD_IMG=ovishpc/ldms-dev

# OVIS prefix INSIDE the container. Please do not change this.
PREFIX=/opt/ovis

#MAKE_INSTALL="make install-strip"
MAKE_INSTALL="make install"

# configure OPTIONS for SOS other than --prefix (*** This is a bash array ***)
SOS_OPTIONS=(
	CFLAGS=\"-O0 -ggdb3\"
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

	CFLAGS=\"-O0 -ggdb3\"
)

# ---- UI components ---- #
PREFIX_UI=${PREFIX}/ui
#NUMSOS_REPO=https://github.com/nick-enoent/numsos
#NUMSOS_BRANCH=b9d1742fe769c49216efa8c35624123e5b995926
NUMSOS_REPO=https://github.com/narategithub/numsos
NUMSOS_BRANCH=edd4522f5c63f65f0d36dd6a87299561fafc85ff
NUMSOS_OPTIONS=()

SOSDBUI_REPO=https://github.com/nick-enoent/sosdb-ui
SOSDBUI_BRANCH=500069d5388fc8d68fe9ae0d6b847c8ce1da95c0
SOSDBUI_OPTIONS=()

SOSDBGRAFANA_REPO=https://github.com/nick-enoent/sosdb-grafana
SOSDBGRAFANA_BRANCH=e5eb5347f3864e2e3447e996cdbe28b8e74b2bb6
#SOSDBGRAFANA_BRANCH=72f25ad0f2ca98eccb00e5599b8cf669a38276fc
SOSDBGRAFANA_OPTIONS=()

#####################################
# ---- scripts/build-dsosds.sh ---- #
#####################################
# ---- dsos data source grafana plugin ---- #
DSOSDS=dsosds # the dsosds build dir relative to the top dir
#DSOSDS_REPO=https://github.com/narategithub/dsosds
DSOSDS_REPO=https://github.com/nick-enoent/dsosds
#DSOSDS_BRANCH=1910e9a6d832b2114ab4421bbb61ea4de95b004d
DSOSDS_BRANCH=7cb80504974a258bcec2752755fe081d36932182
DSOSDS_BUILD_CONT=dsosds-build
DSOSDS_BUILD_IMG=ovishpc/ldms-dev

#
if [[ -f passphrase.sh ]]; then
	# This shall contain DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE env var
	source passphrase.sh
	export DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE
fi
