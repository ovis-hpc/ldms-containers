# ldms-build

# This is a named context defined by compose.yaml
FROM dev
SHELL [ "/bin/bash", "-c" ]

# These are default values, can be overridden by environment variables, or
# variables in docker-bake.hcl file.
ARG LDMS_REPO=https://github.com/ovis-hpc/ldms
ARG LDMS_BRANCH=main
ARG SOS_REPO=https://github.com/ovis-hpc/sos
ARG SOS_BRANCH=b2.6
ARG MAESTRO_REPO=https://github.com/ovis-hpc/maestro
ARG MAESTRO_BRANCH=master
ARG NUMSOS_REPO=https://github.com/narategithub/numsos
ARG NUMSOS_BRANCH=edd4522f5c63f65f0d36dd6a87299561fafc85ff
ARG SOSDBUI_REPO=https://github.com/nick-enoent/sosdb-ui
ARG SOSDBUI_BRANCH=500069d5388fc8d68fe9ae0d6b847c8ce1da95c0
ARG SOSDBGRAFANA_REPO=https://github.com/nick-enoent/sosdb-grafana
ARG SOSDBGRAFANA_BRANCH=e5eb5347f3864e2e3447e996cdbe28b8e74b2bb6
ARG DSOSDS_REPO=https://github.com/nick-enoent/dsosds
ARG DSOSDS_BRANCH=7cb80504974a258bcec2752755fe081d36932182
ARG BUILD_TIME=0
ARG PREFIX=/opt/ovis
ARG PREFIX_UI=${PREFIX}/ui

# record build parameters
RUN <<EOF
cat > /root/build.arg <<EOL
LDMS_REPO="${LDMS_REPO}"
LDMS_BRANCH="${LDMS_BRANCH}"
SOS_REPO="${SOS_REPO}"
SOS_BRANCH="${SOS_BRANCH}"
MAESTRO_REPO="${MAESTRO_REPO}"
MAESTRO_BRANCH="${MAESTRO_BRANCH}"
NUMSOS_REPO="${NUMSOS_REPO}"
NUMSOS_BRANCH="${NUMSOS_BRANCH}"
SOSDBUI_REPO="${SOSDBUI_REPO}"
SOSDBUI_BRANCH="${SOSDBUI_BRANCH}"
SOSDBGRAFANA_REPO="${SOSDBGRAFANA_REPO}"
SOSDBGRAFANA_BRANCH="${SOSDBGRAFANA_BRANCH}"
DSOSDS_REPO="${DSOSDS_REPO}"
DSOSDS_BRANCH="${DSOSDS_BRANCH}"
BUILD_TIME="${BUILD_TIME}"
EOL
EOF
# END record


RUN <<EOF
echo "========== maestro ======================================================"
set -e
pushd /root/
mkdir -p maestro
pushd maestro
git init .
git remote add origin ${MAESTRO_REPO}
git fetch origin --tags
git fetch origin ${MAESTRO_BRANCH}
git checkout -b build FETCH_HEAD
pip3 install --prefix ${PREFIX} .
pushd ${PREFIX}
if [[ -d local ]]; then
	mv local/* ./
	rmdir local
fi
echo "-------------------------------------------------------------------------"
EOF


# sos
RUN <<EOF
echo "========== sos =========================================================="
SOS_OPTIONS=(
	CFLAGS="-ggdb3"
)
set -e
mkdir -p /root/sos
pushd /root/sos
git init .
git remote add origin ${SOS_REPO}
git fetch origin --tags
git fetch origin ${SOS_BRANCH}
git checkout -b build FETCH_HEAD
./autogen.sh
mkdir build
pushd build
../configure --prefix ${PREFIX} ${SOS_OPTIONS[@]}
make
make install
echo "-------------------------------------------------------------------------"
EOF

# ldms
RUN <<EOF
echo "========== ldms ========================================================="
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

	CFLAGS="-ggdb3"
)
set -e
mkdir -p /root/ldms
pushd /root/ldms
git init .
git remote add origin ${LDMS_REPO}
git fetch origin --tags
git fetch origin ${LDMS_BRANCH}
git checkout -b build FETCH_HEAD
git config user.name 'root'
git config user.email 'root@localhost'
# annotated tag 'main' b/c configure script uses annotated tag for LDMS Version.
# This added tag only be used for building 'main'.
[[ "${LDMS_BRANCH}" != "main" ]] || {
	MAIN_TAG=$( git show -s --format=4.6.0-%h origin/main )
	git tag -f -a -m ${MAIN_TAG} ${MAIN_TAG} origin/main
}
./autogen.sh
mkdir -p build
pushd build
../configure --prefix ${PREFIX} ${OVIS_OPTIONS[@]}
make
make install
pushd /etc/profile.d
ln -s ${PREFIX}/etc/profile.d/set-ovis-variables.sh
popd
pushd /etc/ld.so.conf.d
ln -s ${PREFIX}/etc/ld.so.conf.d/ovis-ld-so.conf
ldconfig
popd
echo "-------------------------------------------------------------------------"
EOF
# end ldms

RUN <<EOF
echo "========== numsos ======================================================="
set -e
NUMSOS_OPTIONS=()
if [[ -n "${NUMSOS_REPO}" ]]; then
  mkdir -p /root/numsos
  pushd /root/numsos
  git init .
  git remote add origin ${NUMSOS_REPO}
  git fetch origin ${NUMSOS_BRANCH}
  git checkout -b build FETCH_HEAD
  ./autogen.sh
  mkdir -p build
  pushd build
  ../configure --prefix=${PREFIX} --with-sos=${PREFIX} ${NUMSOS_OPTIONS[@]} PYTHON=python3
  make
  make install
fi
echo "-------------------------------------------------------------------------"
EOF


RUN <<EOF
echo "========== sosdb-ui ====================================================="
set -e
SOSDBUI_OPTIONS=()
if [[ -n "${SOSDBUI_REPO}" ]]; then
  mkdir -p /root/sosdb-ui
  pushd /root/sosdb-ui
  git init .
  git remote add origin ${SOSDBUI_REPO}
  git fetch origin ${SOSDBUI_BRANCH}
  git checkout -b build FETCH_HEAD
  ./autogen.sh
  mkdir -p build
  pushd build
  ../configure --prefix ${PREFIX_UI} ${SOSDBUI_OPTIONS[@]}
  make
  make install
fi
echo "-------------------------------------------------------------------------"
EOF


RUN <<EOF
echo "========== sosdb-grafana ================================================"
set -e
SOSDBGRAFANA_OPTIONS=()
if [[ -n "${SOSDBGRAFANA_REPO}" ]]; then
  mkdir -p /root/sosdb-grafana
  pushd /root/sosdb-grafana
  git init .
  git remote add origin ${SOSDBGRAFANA_REPO}
  git fetch origin ${SOSDBGRAFANA_BRANCH}
  git checkout -b build FETCH_HEAD
  ./autogen.sh
  mkdir -p build
  pushd build
  ../configure --prefix ${PREFIX_UI} ${SOSDBGRAFANA_OPTIONS[@]}
  make
  make install
fi
echo "-------------------------------------------------------------------------"
EOF


RUN <<EOF
if [[ -n "${DSOSDS_REPO}" ]]; then
  echo "==== Checking out ${DSOSDS_REPO} - ${DSOSDS_BRANCH} ===="
  mkdir -p /root/dsosds
  cd /root/dsosds
  git init .
  git remote add origin ${DSOSDS_REPO}
  git fetch origin ${DSOSDS_BRANCH}
  git checkout -b out FETCH_HEAD
  echo "==== Installing the dependencies ===="
  mkdir -p .npm
  npm install --cache /root/dsosds/.npm --production
fi
EOF
