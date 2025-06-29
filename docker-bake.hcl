# ------------------ variables ------------------ #
variable "TAG" {
  default = "unstable"
}

variable "ARCH" {
  default = "amd64"
}

variable "BUILD_TIME" {
  default = "0"
}

variable "LDMS_REPO" {
  default = "https://github.com/ovis-hpc/ldms"
}

variable "LDMS_BRANCH" {
  default = "main"
}

variable "SOS_REPO" {
  default = "https://github.com/ovis-hpc/sos"
}

variable "SOS_BRANCH" {
  default = "b2.6"
}

variable "MAESTRO_REPO" {
  default = "https://github.com/ovis-hpc/maestro"
}

variable "MAESTRO_BRANCH" {
  default = "master"
}

variable "NUMSOS_REPO" {
  default = "https://github.com/narategithub/numsos"
}

variable "NUMSOS_BRANCH" {
  default = "edd4522f5c63f65f0d36dd6a87299561fafc85ff"
}

variable "SOSDBUI_REPO" {
  default = "https://github.com/nick-enoent/sosdb-ui"
}

variable "SOSDBUI_BRANCH" {
  default = "500069d5388fc8d68fe9ae0d6b847c8ce1da95c0"
}

variable "SOSDBGRAFANA_REPO" {
  default = "https://github.com/nick-enoent/sosdb-grafana"
}

variable "SOSDBGRAFANA_BRANCH" {
  default = "e5eb5347f3864e2e3447e996cdbe28b8e74b2bb6"
}

# ------------------ targets ------------------ #
group "default" {
  targets = [
    "ldms-dev",
    "ldms-dev-ubuntu-2204",
    "ldms-dev-ubuntu-2404",
    "ldms-dev-alma-8",
    "ldms-dev-alma-9",
    "ldms-dev-opensuse-15",
    "ldms-build",
    "ldms-agg",
    "ldms-samp",
    "ldms-maestro",
    "ldms-web-svc",
    "ldms-grafana",
  ]
}

group "manifest" {
  targets = [
    "manifest-ldms-dev",
    "manifest-ldms-dev-ubuntu-2204",
    "manifest-ldms-dev-ubuntu-2404",
    "manifest-ldms-dev-alma-8",
    "manifest-ldms-dev-alma-9",
    "manifest-ldms-dev-opensuse-15",
    "manifest-ldms-build",
    "manifest-ldms-agg",
    "manifest-ldms-samp",
    "manifest-ldms-maestro",
    "manifest-ldms-web-svc",
    "manifest-ldms-grafana",
  ]
}

target "_common" {
  platforms = [ "linux/${ARCH}" ]
}

target "_manifest_common" {
  platforms = [ "linux/amd64", "linux/arm64" ]
}

target "ldms-dev" {
  inherits = [ "_common" ]
  context = "buildx/ldms-dev"
  tags = [ "ovishpc/ldms-dev:${TAG}-${ARCH}" ]
}

target "ldms-dev-ubuntu-2204" {
  inherits = [ "_common" ]
  context = "buildx/ldms-dev-ubuntu-2204"
  tags = [ "ovishpc/ldms-dev-ubuntu-2204:${TAG}-${ARCH}" ]
}

target "ldms-dev-ubuntu-2404" {
  inherits = [ "_common" ]
  context = "buildx/ldms-dev-ubuntu-2404"
  tags = [ "ovishpc/ldms-dev-ubuntu-2404:${TAG}-${ARCH}" ]
}

target "ldms-dev-alma-8" {
  inherits = [ "_common" ]
  context = "buildx/ldms-dev-alma-8"
  tags = [ "ovishpc/ldms-dev-alma-8:${TAG}-${ARCH}" ]
}

target "ldms-compat-alma-8" {
  inherits = [ "_common" ]
  context = "buildx/ldms-compat-alma-8"
  tags = [ "ovishpc/ldms-compat-alma-8:${TAG}-${ARCH}" ]
  contexts = {
    build = "target:ldms-dev-alma-8"
  }
}

target "ldms-dev-alma-9" {
  inherits = [ "_common" ]
  context = "buildx/ldms-dev-alma-9"
  tags = [ "ovishpc/ldms-dev-alma-9:${TAG}-${ARCH}" ]
}

target "ldms-dev-opensuse-15" {
  inherits = [ "_common" ]
  context = "buildx/ldms-dev-opensuse-15"
  tags = [ "ovishpc/ldms-dev-opensuse-15:${TAG}-${ARCH}" ]
}

target "ldms-build" {
  inherits = [ "_common" ]
  context = "buildx/ldms-build"
  tags = [ "ovishpc/ldms-build:${TAG}-${ARCH}" ]
  contexts = {
    dev = "target:ldms-dev"
  }
  args = {
    BUILD_TIME          = "${BUILD_TIME}"
    LDMS_REPO           = "${LDMS_REPO}"
    LDMS_BRANCH         = "${LDMS_BRANCH}"
    SOS_REPO            = "${SOS_REPO}"
    SOS_BRANCH          = "${SOS_BRANCH}"
    MAESTRO_REPO        = "${MAESTRO_REPO}"
    MAESTRO_BRANCH      = "${MAESTRO_BRANCH}"
    NUMSOS_REPO         = "${NUMSOS_REPO}"
    NUMSOS_BRANCH       = "${NUMSOS_BRANCH}"
    SOSDBUI_REPO        = "${SOSDBUI_REPO}"
    SOSDBUI_BRANCH      = "${SOSDBUI_BRANCH}"
    SOSDBGRAFANA_REPO   = "${SOSDBGRAFANA_REPO}"
    SOSDBGRAFANA_BRANCH = "${SOSDBGRAFANA_BRANCH}"
  }
}

target "ldms-agg" {
  inherits = [ "_common" ]
  context = "buildx/ldms-agg"
  tags = [ "ovishpc/ldms-agg:${TAG}-${ARCH}" ]
  contexts = {
    build = "target:ldms-build"
  }
}

target "ldms-samp" {
  inherits = [ "_common" ]
  context = "buildx/ldms-samp"
  tags = [ "ovishpc/ldms-samp:${TAG}-${ARCH}" ]
  contexts = {
    build = "target:ldms-build"
  }
}

target "ldms-maestro" {
  inherits = [ "_common" ]
  context = "buildx/ldms-maestro"
  tags = [ "ovishpc/ldms-maestro:${TAG}-${ARCH}" ]
  contexts = {
    build = "target:ldms-build"
  }
}

target "ldms-web-svc" {
  inherits = [ "_common" ]
  context = "buildx/ldms-web-svc"
  tags = [ "ovishpc/ldms-web-svc:${TAG}-${ARCH}" ]
  contexts = {
    build = "target:ldms-build"
  }
}

target "ldms-grafana" {
  inherits = [ "_common" ]
  context = "buildx/ldms-grafana"
  tags = [ "ovishpc/ldms-grafana:${TAG}-${ARCH}" ]
  contexts = {
    build = "target:ldms-build"
  }
}

# Manifest targets

target "manifest-ldms-dev" {
  inherits = [ "_manifest_common" ]
  context = "manifest"
  tags = [ "ovishpc/ldms-dev:${TAG}" ]
  args = {
    BASE = "ovishpc/ldms-dev:${TAG}"
  }
}

target "manifest-ldms-dev-ubuntu-2204" {
  inherits = [ "_manifest_common" ]
  context = "manifest"
  tags = [ "ovishpc/ldms-dev-ubuntu-2204:${TAG}" ]
  args = {
    BASE = "ovishpc/ldms-dev-ubuntu-2204:${TAG}"
  }
}

target "manifest-ldms-dev-ubuntu-2404" {
  inherits = [ "_manifest_common" ]
  context = "manifest"
  tags = [ "ovishpc/ldms-dev-ubuntu-2404:${TAG}" ]
  args = {
    BASE = "ovishpc/ldms-dev-ubuntu-2404:${TAG}"
  }
}

target "manifest-ldms-dev-alma-8" {
  inherits = [ "_manifest_common" ]
  context = "manifest"
  tags = [ "ovishpc/ldms-dev-alma-8:${TAG}" ]
  args = {
    BASE = "ovishpc/ldms-dev-alma-8:${TAG}"
  }
}

target "manifest-ldms-dev-alma-9" {
  inherits = [ "_manifest_common" ]
  context = "manifest"
  tags = [ "ovishpc/ldms-dev-alma-9:${TAG}" ]
  args = {
    BASE = "ovishpc/ldms-dev-alma-9:${TAG}"
  }
}

target "manifest-ldms-dev-opensuse-15" {
  inherits = [ "_manifest_common" ]
  context = "manifest"
  tags = [ "ovishpc/ldms-dev-opensuse-15:${TAG}" ]
  args = {
    BASE = "ovishpc/ldms-dev-opensuse-15:${TAG}"
  }
}

target "manifest-ldms-build" {
  inherits = [ "_manifest_common" ]
  context = "manifest"
  tags = [ "ovishpc/ldms-build:${TAG}" ]
  args = {
    BASE = "ovishpc/ldms-build:${TAG}"
  }
}

target "manifest-ldms-agg" {
  inherits = [ "_manifest_common" ]
  context = "manifest"
  tags = [ "ovishpc/ldms-agg:${TAG}" ]
  args = {
    BASE = "ovishpc/ldms-agg:${TAG}"
  }
}

target "manifest-ldms-samp" {
  inherits = [ "_manifest_common" ]
  context = "manifest"
  tags = [ "ovishpc/ldms-samp:${TAG}" ]
  args = {
    BASE = "ovishpc/ldms-samp:${TAG}"
  }
}

target "manifest-ldms-maestro" {
  inherits = [ "_manifest_common" ]
  context = "manifest"
  tags = [ "ovishpc/ldms-maestro:${TAG}" ]
  args = {
    BASE = "ovishpc/ldms-maestro:${TAG}"
  }
}

target "manifest-ldms-web-svc" {
  inherits = [ "_manifest_common" ]
  context = "manifest"
  tags = [ "ovishpc/ldms-web-svc:${TAG}" ]
  args = {
    BASE = "ovishpc/ldms-web-svc:${TAG}"
  }
}

target "manifest-ldms-grafana" {
  inherits = [ "_manifest_common" ]
  context = "manifest"
  tags = [ "ovishpc/ldms-grafana:${TAG}" ]
  args = {
    BASE = "ovishpc/ldms-grafana:${TAG}"
  }
}

# EOF
