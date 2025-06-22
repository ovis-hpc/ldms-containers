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

# checkout ldms
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

PREFIX=/opt/ovis
PREFIX_UI=${PREFIX}/ui

NUMSOS_OPTIONS=()
SOSDBUI_OPTIONS=()

SOS_OPTIONS=(
	CFLAGS="-ggdb3"
)

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
pushd /root/

mkdir -p ldms sos maestro

pushd ldms
git init .
git remote add origin ${LDMS_REPO}
git fetch origin --tags
git fetch origin ${LDMS_BRANCH}
git checkout -b build FETCH_HEAD
git config user.name 'root'
git config user.email 'root@localhost'
# retag v4.5.0 as annotated tag
git tag -f -a -m 'v4.5.0' v4.5.0 v4.5.0
popd # ldms

pushd sos
git init .
git remote add origin ${SOS_REPO}
git fetch origin --tags
git fetch origin ${SOS_BRANCH}
git checkout -b build FETCH_HEAD
popd # sos

pushd maestro
git init .
git remote add origin ${MAESTRO_REPO}
git fetch origin --tags
git fetch origin ${MAESTRO_BRANCH}
git checkout -b build FETCH_HEAD
popd # maestro

echo "========== maestro ======================================================"
pushd maestro
pip3 install --prefix ${PREFIX} .
pushd ${PREFIX}
if [[ -d local ]]; then
	mv local/* ./
	rmdir local
fi
popd # ${PREFIX}
popd # maestro
echo "-------------------------------------------------------------------------"

echo "========== sos =========================================================="
pushd sos
./autogen.sh
mkdir build
pushd build
../configure --prefix ${PREFIX} ${SOS_OPTIONS[@]}
make
make install
popd # build
popd # sos
echo "-------------------------------------------------------------------------"

echo "========== ldms ========================================================="
pushd ldms
./autogen.sh
mkdir build
pushd build
../configure --prefix ${PREFIX} ${OVIS_OPTIONS[@]}
make
make install
popd # build
popd # ldms
echo "-------------------------------------------------------------------------"

pushd /etc/profile.d
ln -s /opt/ovis/etc/profile.d/set-ovis-variables.sh
popd

pushd /etc/ld.so.conf.d
ln -s /opt/ovis/etc/ld.so.conf.d/ovis-ld-so.conf
ldconfig
popd

if [[ -n "${NUMSOS_REPO}" ]]; then
echo "========== numsos ======================================================="
  mkdir -p numsos
  pushd numsos
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
  popd # build
  popd # numsos
echo "-------------------------------------------------------------------------"
fi

if [[ -n "${SOSDBUI_REPO}" ]]; then
echo "========== sosdb-ui ====================================================="
  mkdir -p sosdb-ui
  pushd sosdb-ui
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
  popd # build
  popd # sosdb-ui
echo "-------------------------------------------------------------------------"
fi

if [[ -n "${SOSDBGRAFANA_REPO}" ]]; then
echo "========== sosdb-grafana ================================================"
  mkdir -p sosdb-grafana
  pushd sosdb-grafana
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
  popd # build
  popd # sosdb-grafana
echo "-------------------------------------------------------------------------"
fi

if [[ -n "${DSOSDS_REPO}" ]]; then
  mkdir -p dsosds
  cd dsosds
  echo "==== Checking out ${DSOSDS_REPO} - ${DSOSDS_BRANCH} ===="
  git init .
  git remote add origin ${DSOSDS_REPO}
  git fetch origin ${DSOSDS_BRANCH}
  git checkout -b out FETCH_HEAD
  echo "==== Installing the dependencies ===="
  mkdir .npm
  npm install --cache ${DSOSDS}/.npm --production
fi

EOF
