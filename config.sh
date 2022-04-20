
# docker network config
NET=ldms
SUBNET=192.168.40.0/24

#### docker run options ####
CAPADDS=(
	#SYS_ADMIN
	#SYS_PTRACE
)
OPT_CAPADDS=( ${CAPADDS[@]/#/--cap-add=} )

VOLUMES=(
	# a list of volumes ( "path-in-host:path-in-cont:mode" ) for '-v' option
	# in docker-run
)

# Bash array containing sampler plugins to feed to ldmsd-conf script. Please
# note that if SAMPLER_CONF_FILE is specified, ldmsd-conf won't be used to
# generate ldmsd configuration for the sampler containers.
SAMPLER_PLUGIN_LIST=( meminfo loadavg procstat)

#### build options ####

# The location of OVIS repository. The default is "https://github.com/ovis-hpc/ovis"
#OVIS_REPO="https://github.com/ovis-hpc/ovis"
#OVIS_REPO="https://github.com/narategithub/ovis"

# Revision of OVIS to build; if not set, `OVIS-4` is the default
#OVIS_REV=OVIS-4
#OVIS_REV=fix_store_csv

# The location of SOS repository. The default is "https://github.com/ovis-hpc/sos"
#SOS_REPO="https://github.com/ovis-hpc/sos"

# Revision of SOS to build; if not set, `SOS-5` is the default
#SOS_REV=SOS-5
