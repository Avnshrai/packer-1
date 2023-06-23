#!/bin/bash

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load Grafana environment
. /opt/coredge/scripts/grafana-env.sh

# Load MySQL Client environment for 'mysql_remote_execute' (after 'grafana-env.sh' so that MODULE is not set to a wrong value)
if [[ -f /opt/coredge/scripts/mysql-client-env.sh ]]; then
    . /opt/coredge/scripts/mysql-client-env.sh
elif [[ -f /opt/coredge/scripts/mysql-env.sh ]]; then
    . /opt/coredge/scripts/mysql-env.sh
elif [[ -f /opt/coredge/scripts/mariadb-env.sh ]]; then
    . /opt/coredge/scripts/mariadb-env.sh
fi

# Load libraries
. /opt/coredge/scripts/liblog.sh
. /opt/coredge/scripts/libgrafana.sh

# Ensure Grafana environment variables are valid
grafana_validate

# Ensure Grafana is initialized
grafana_initialize